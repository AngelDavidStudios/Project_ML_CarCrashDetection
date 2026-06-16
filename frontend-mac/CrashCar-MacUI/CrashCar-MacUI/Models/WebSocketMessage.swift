//
//  WebSocketMessage.swift
//  CrashCar-MacUI
//
//  Sesión 5 — Protocolo del WebSocket `/ws/detect` del backend FastAPI.
//
//  Modela los mensajes salientes (cliente → servidor) y entrantes
//  (servidor → cliente) del pipeline de detección. Es el espejo del
//  discriminador `type` que usa `backend/app.py`.
//
//  Concurrencia: todos los tipos son `Sendable` (structs de valor) para poder
//  cruzar dominios de aislamiento — el `WebSocketService` los emite por un
//  `AsyncStream` que consumen ViewModels en otros contextos.
//

import Foundation

// MARK: - Payloads entrantes

/// `video_info`: dimensiones y cadencia del vídeo que el backend va a procesar.
nonisolated struct VideoInfo: Sendable, Equatable {
    let width: Int
    let height: Int
    let fps: Double
    let originalFps: Double
    let totalFrames: Int
    let message: String
}

/// `accident`: accidente detectado en un frame. `frameNumber`/`location` son
/// opcionales porque no siempre llegan (p. ej. sin metadatos de cámara).
nonisolated struct AccidentEvent: Sendable, Equatable {
    let frameNumber: Int?
    let confidence: Double
    let accidentType: String
    let location: String?
    let message: String?
    let timestamp: Double?
}

/// `image_saved`: el backend persistió la imagen del accidente y devuelve su URL
/// relativa (`/accident_images/<file>`), servible estáticamente por el frontend.
///
/// El init expone los campos relevantes para crear un incidente primero, con
/// `frameNumber`/`message` opcionales al final, para construirlo cómodamente
/// desde el `DetectionViewModel` y los tests.
nonisolated struct ImageSavedEvent: Sendable, Equatable {
    let imageUrl: String
    let confidence: Double?
    let accidentType: String?
    let location: String?
    let timestamp: Double?
    let frameNumber: Int?
    let message: String?

    init(imageUrl: String,
         confidence: Double? = nil,
         accidentType: String? = nil,
         location: String? = nil,
         timestamp: Double? = nil,
         frameNumber: Int? = nil,
         message: String? = nil) {
        self.imageUrl = imageUrl
        self.confidence = confidence
        self.accidentType = accidentType
        self.location = location
        self.timestamp = timestamp
        self.frameNumber = frameNumber
        self.message = message
    }
}

/// `progress`: progreso de procesado emitido cada 30 frames.
nonisolated struct ProgressEvent: Sendable, Equatable {
    let frameCount: Int
    let progress: Double
    let message: String?
}

/// `processing_complete`: fin del procesado del vídeo.
nonisolated struct ProcessingCompleteEvent: Sendable, Equatable {
    let accidentFound: Bool
    let totalFrames: Int
    let location: String?
    let message: String?
    let timestamp: Double?
}

// MARK: - WebSocketMessage

/// Un mensaje del protocolo `/ws/detect`, en cualquiera de las dos direcciones.
nonisolated enum WebSocketMessage: Sendable, Equatable {

    // Salientes (cliente → servidor)
    case ping
    case processVideo(url: String, cameraName: String, latitude: Double?, longitude: Double?, cameraId: String?)

    // Entrantes (servidor → cliente)
    /// Primer mensaje (sin `type`) que confirma la conexión al servicio.
    case connected(message: String)
    case ready(message: String)
    case pong
    case videoInfo(VideoInfo)
    case frame(base64: String, frameNumber: Int)
    case accident(AccidentEvent)
    case imageSaved(ImageSavedEvent)
    case progress(ProgressEvent)
    case processingComplete(ProcessingCompleteEvent)
    case error(message: String)
}

// MARK: - Errores

enum WebSocketMessageError: Error, Equatable {
    /// La cadena no era UTF-8 válida.
    case invalidUTF8
    /// `type` desconocido en un mensaje entrante.
    case unknownType(String)
    /// Faltaba un campo obligatorio para el tipo de mensaje.
    case missingField(String)
    /// Se intentó serializar un caso entrante como saliente.
    case notOutgoing
    /// El base64 de un frame no decodificaba a `Data`.
    case invalidBase64
    /// `Data` válido pero no decodificable como imagen.
    case frameDecodeFailed
}

// MARK: - Parsing entrante

nonisolated extension WebSocketMessage {

    /// DTO interno con todos los campos posibles como opcionales. Se decodifica
    /// con `convertFromSnakeCase`, así que `frame_number` → `frameNumber`, etc.
    nonisolated private struct Payload: Decodable {
        let type: String?
        let message: String?
        // video_info
        let width: Int?
        let height: Int?
        let fps: Double?
        let originalFps: Double?
        let totalFrames: Int?
        // frame
        let frame: String?
        let frameNumber: Int?
        // accident / image_saved
        let confidence: Double?
        let accidentType: String?
        let location: String?
        let imageUrl: String?
        let timestamp: Double?
        // progress
        let frameCount: Int?
        let progress: Double?
        // processing_complete
        let accidentFound: Bool?
    }

    /// Parsea un mensaje entrante desde su representación JSON.
    init(json: String) throws {
        guard let data = json.data(using: .utf8) else {
            throw WebSocketMessageError.invalidUTF8
        }
        try self.init(data: data)
    }

    /// Parsea un mensaje entrante desde los bytes recibidos por el socket.
    init(data: Data) throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let p = try decoder.decode(Payload.self, from: data)

        switch p.type {
        case "ready":
            self = .ready(message: p.message ?? "")

        case "pong":
            self = .pong

        case "video_info":
            self = .videoInfo(VideoInfo(
                width: p.width ?? 0,
                height: p.height ?? 0,
                fps: p.fps ?? 0,
                originalFps: p.originalFps ?? 0,
                totalFrames: p.totalFrames ?? 0,
                message: p.message ?? ""))

        case "frame":
            guard let frame = p.frame else {
                throw WebSocketMessageError.missingField("frame")
            }
            self = .frame(base64: frame, frameNumber: p.frameNumber ?? 0)

        case "accident":
            self = .accident(AccidentEvent(
                frameNumber: p.frameNumber,
                confidence: p.confidence ?? 0,
                accidentType: p.accidentType ?? "",
                location: p.location,
                message: p.message,
                timestamp: p.timestamp))

        case "image_saved":
            guard let imageUrl = p.imageUrl else {
                throw WebSocketMessageError.missingField("image_url")
            }
            self = .imageSaved(ImageSavedEvent(
                imageUrl: imageUrl,
                confidence: p.confidence,
                accidentType: p.accidentType,
                location: p.location,
                timestamp: p.timestamp,
                frameNumber: p.frameNumber,
                message: p.message))

        case "progress":
            self = .progress(ProgressEvent(
                frameCount: p.frameCount ?? 0,
                progress: p.progress ?? 0,
                message: p.message))

        case "processing_complete":
            self = .processingComplete(ProcessingCompleteEvent(
                accidentFound: p.accidentFound ?? false,
                totalFrames: p.totalFrames ?? 0,
                location: p.location,
                message: p.message,
                timestamp: p.timestamp))

        case "error":
            self = .error(message: p.message ?? "")

        case nil:
            // El primer mensaje del backend ("Connected to accident detection
            // service") no lleva `type`.
            self = .connected(message: p.message ?? "")

        case let other?:
            throw WebSocketMessageError.unknownType(other)
        }
    }
}

// MARK: - Serialización saliente

nonisolated extension WebSocketMessage {

    nonisolated private struct ProcessVideoDTO: Encodable {
        let type = "process_video"
        let videoUrl: String
        let cameraName: String
        let latitude: Double?
        let longitude: Double?
        let cameraId: String?

        enum CodingKeys: String, CodingKey {
            case type
            case videoUrl = "video_url"
            case cameraName = "camera_name"
            case latitude
            case longitude
            case cameraId = "camera_id"
        }
    }

    /// Serializa un caso saliente (`ping` / `processVideo`) a JSON para enviarlo.
    /// Lanza `notOutgoing` para cualquier caso entrante.
    func encoded() throws -> Data {
        switch self {
        case .ping:
            return try JSONEncoder().encode(["type": "ping"])

        case let .processVideo(url, cameraName, latitude, longitude, cameraId):
            let dto = ProcessVideoDTO(
                videoUrl: url,
                cameraName: cameraName,
                latitude: latitude,
                longitude: longitude,
                cameraId: cameraId)
            return try JSONEncoder().encode(dto)

        default:
            throw WebSocketMessageError.notOutgoing
        }
    }
}
