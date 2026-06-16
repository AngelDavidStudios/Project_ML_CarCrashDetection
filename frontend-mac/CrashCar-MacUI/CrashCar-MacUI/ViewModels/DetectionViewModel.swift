//
//  DetectionViewModel.swift
//  CrashCar-MacUI
//
//  Sesión 6 — Coordina la detección: prepara el vídeo (`VideoService`), abre el
//  WebSocket (`WebSocketService`), traduce los mensajes entrantes a logs y crea
//  un incidente en DynamoDB (`IncidentViewModel`) cuando llega `image_saved`.
//
//  Concurrencia (Approachable Concurrency): `@MainActor` por el aislamiento por
//  defecto. El consumo del `AsyncStream` de mensajes y la preparación del vídeo
//  son `Task`s con `async/await` — sin DispatchQueue ni completion handlers.
//

import Foundation
import Combine
import CoreGraphics
import Amplify

// MARK: - Abstracciones inyectables

/// Capacidad de crear un incidente a partir de una detección. La implementa
/// `IncidentViewModel`; permite inyectar un mock en los tests sin tocar AWS.
@MainActor
protocol IncidentCreating {
    @discardableResult
    func createIncident(from payload: DetectionPayload) async throws -> String
}

extension IncidentViewModel: IncidentCreating {}

/// Superficie del `WebSocketService` que necesita el `DetectionViewModel`,
/// abstraída para poder inyectar un mock sin red en los tests.
@MainActor
protocol WebSocketServicing: AnyObject {
    /// Flujo de mensajes entrantes ya parseados.
    var messages: AsyncStream<WebSocketMessage> { get }
    /// Publisher del último frame decodificado (para reflejarlo en la UI).
    var lastFramePublisher: AnyPublisher<CGImage?, Never> { get }
    func connect(to url: URL)
    func disconnect()
    func send(_ message: WebSocketMessage)
}

extension WebSocketService: WebSocketServicing {
    var lastFramePublisher: AnyPublisher<CGImage?, Never> {
        $lastFrame.eraseToAnyPublisher()
    }
}

// MARK: - Log de detección

/// Una entrada del log de detección que se muestra en el panel derecho.
struct DetectionLog: Identifiable, Sendable, Equatable {
    enum Severity: String, Sendable {
        case info, success, warning, error
    }

    let id = UUID()
    let timestamp: Date
    let message: String
    let severity: Severity

    init(message: String, severity: Severity, timestamp: Date = Date()) {
        self.message = message
        self.severity = severity
        self.timestamp = timestamp
    }
}

// MARK: - ViewModel

@MainActor
final class DetectionViewModel: ObservableObject {

    /// Fase del ciclo de detección, para dirigir la UI.
    enum Phase: Sendable, Equatable {
        case idle, preparing, connecting, detecting, completed, failed
    }

    // MARK: Estado publicado

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var logs: [DetectionLog] = []
    @Published private(set) var currentFrame: CGImage?
    @Published private(set) var selectedVideoURL: URL?
    @Published private(set) var progress: Double = 0

    var isBusy: Bool { phase == .preparing || phase == .connecting || phase == .detecting }

    // MARK: Dependencias

    private let incidentViewModel: IncidentCreating
    private let imageService: AccidentImageUploading
    private let videoService: VideoService
    private let wsService: WebSocketServicing
    private let notificationService: NotificationService
    private let backendURL: URL

    // MARK: Estado interno

    private var detectionTask: Task<Void, Never>?
    private var observeTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private var preparedPath: String?
    private var cameraName = ""
    private var latitude: Double?
    private var longitude: Double?

    init(incidentViewModel: IncidentCreating,
         imageService: AccidentImageUploading,
         wsService: WebSocketServicing,
         videoService: VideoService = VideoService(),
         notificationService: NotificationService,
         backendURL: URL = URL(string: AppSettings.defaultBackendURLString)!) {
        self.incidentViewModel = incidentViewModel
        self.imageService = imageService
        self.wsService = wsService
        self.videoService = videoService
        self.notificationService = notificationService
        self.backendURL = backendURL
    }

    /// Conveniencia para la app real: usa las implementaciones concretas y la URL
    /// del backend configurada en `AppSettings`. Construye las dependencias Amplify
    /// en cuerpo MainActor (evita defaults evaluados sin aislamiento).
    convenience init() {
        self.init(incidentViewModel: IncidentViewModel(),
                  imageService: ImageUploadService(httpBaseURL: AppSettings.shared.backendHTTPBaseURL),
                  wsService: WebSocketService(),
                  notificationService: NotificationService.shared,
                  backendURL: AppSettings.shared.backendWebSocketURL)
    }

    // MARK: - Acciones del operador

    /// Abre el selector de vídeo y guarda la URL elegida.
    func pickVideo() {
        guard let url = videoService.pickVideo() else { return }
        selectedVideoURL = url
        appendLog("Selected \(url.lastPathComponent)", .info)
    }

    /// Quita el vídeo seleccionado y detiene cualquier detección en curso.
    func removeVideo() {
        stop()
        selectedVideoURL = nil
        currentFrame = nil
        progress = 0
        logs.removeAll()
        phase = .idle
    }

    /// Arranca la detección sobre el vídeo seleccionado con los metadatos de cámara.
    func startDetection(cameraName: String, latitude: Double?, longitude: Double?) {
        guard let videoURL = selectedVideoURL, detectionTask == nil else { return }
        self.cameraName = cameraName.isEmpty ? "Unknown Camera" : cameraName
        self.latitude = latitude
        self.longitude = longitude
        phase = .preparing
        detectionTask = Task { [weak self] in
            await self?.runDetection(videoURL: videoURL)
        }
    }

    /// Detiene la detección y libera la conexión.
    func stop() {
        detectionTask?.cancel(); detectionTask = nil
        observeTask?.cancel(); observeTask = nil
        cancellables.removeAll()
        wsService.disconnect()
    }

    // MARK: - Flujo interno

    private func runDetection(videoURL: URL) async {
        do {
            appendLog("Preparing video…", .info)
            preparedPath = try await videoService.prepareForFastAPI(url: videoURL)

            phase = .connecting
            appendLog("Connecting to backend…", .info)
            startObserving()
            wsService.connect(to: backendURL)
        } catch {
            phase = .failed
            appendLog("Failed to prepare video: \(error.localizedDescription)", .error)
        }
    }

    private func startObserving() {
        guard observeTask == nil else { return }

        wsService.lastFramePublisher
            .sink { [weak self] frame in self?.currentFrame = frame }
            .store(in: &cancellables)

        observeTask = Task { [weak self] in
            guard let self else { return }
            for await message in self.wsService.messages {
                self.handle(message)
            }
        }
    }

    private func handle(_ message: WebSocketMessage) {
        switch message {
        case .connected:
            appendLog("Connected to detection service", .info)

        case .ready:
            appendLog("Backend ready", .success)
            sendProcessVideoRequest()

        case let .videoInfo(info):
            appendLog("Processing \(info.width)×\(info.height) @ \(Int(info.fps)) FPS", .info)

        case let .accident(event):
            appendLog("⚠️ \(event.accidentType) — \(event.confidence.asPercent)", .warning)
            Task { [notificationService] in
                await notificationService.sendAccidentAlert(
                    type: event.accidentType,
                    location: event.location,
                    confidence: event.confidence)
            }

        case let .imageSaved(event):
            // Crear el incidente sin bloquear el consumo de frames.
            Task { [weak self] in await self?.handleImageSaved(event) }

        case let .progress(event):
            progress = event.progress

        case let .processingComplete(event):
            progress = 1
            phase = .completed
            let summary = event.accidentFound ? "accidents detected" : "no accidents"
            appendLog("Processing complete — \(summary)", .success)
            wsService.disconnect()

        case let .error(message):
            phase = .failed
            appendLog(message, .error)

        case .frame, .pong, .ping, .processVideo:
            // `frame` se refleja vía `lastFramePublisher`; el resto no aplica aquí.
            break
        }
    }

    private func sendProcessVideoRequest() {
        guard let path = preparedPath else { return }
        wsService.send(.processVideo(
            url: path,
            cameraName: cameraName,
            latitude: latitude,
            longitude: longitude,
            cameraId: nil))
        phase = .detecting
        appendLog("Detection started", .info)
    }

    /// Traduce un `image_saved` en un incidente persistido. `internal` para que
    /// los tests lo ejerciten directamente.
    func handleImageSaved(_ event: ImageSavedEvent) async {
        // Subir la imagen a S3 primero. Si falla, el incidente se crea igual sin
        // `s3ImageKey` (la subida no debe bloquear la persistencia del incidente).
        var s3ImageKey: String?
        do {
            let key = try await imageService.uploadAccidentImage(from: event.imageUrl)
            s3ImageKey = key
            appendLog("Accident image uploaded to S3: \(key)", .success)
        } catch {
            // `localizedDescription` de los errores de Amplify suele ser vago; se
            // registra la descripción completa en consola para diagnosticar.
            Amplify.Logging.error("S3 upload failed for \(event.imageUrl): \(String(describing: error))")
            appendLog("S3 upload failed; saving incident without image: \(error.localizedDescription)", .warning)
        }

        let payload = DetectionPayload(
            confidenceScore: event.confidence ?? 0,
            accidentType: event.accidentType ?? "unknown",
            location: event.location,
            latitude: latitude,
            longitude: longitude,
            imageUrl: event.imageUrl,
            s3ImageKey: s3ImageKey,
            detectedAt: event.timestamp.map { Date(timeIntervalSince1970: $0) } ?? Date())
        do {
            let id = try await incidentViewModel.createIncident(from: payload)
            appendLog("Incident created (\(id.prefix(8))) — \(event.accidentType ?? "accident")", .success)
        } catch {
            appendLog("Failed to create incident: \(error.localizedDescription)", .error)
        }
    }

    // MARK: - Utilidades

    private func appendLog(_ message: String, _ severity: DetectionLog.Severity) {
        logs.append(DetectionLog(message: message, severity: severity))
    }
}
