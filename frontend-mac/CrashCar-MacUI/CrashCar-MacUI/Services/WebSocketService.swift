//
//  WebSocketService.swift
//  CrashCar-MacUI
//
//  Sesión 5 — Cliente WebSocket del pipeline de detección (`/ws/detect`).
//
//  Replica el comportamiento del `page.tsx` del frontend Next.js: conexión,
//  ping cada 30 s, reconexión con backoff (1006 → 3 s, resto → 1 s) y decodificado
//  de frames base64 a `CGImage`.
//
//  Concurrencia (Approachable Concurrency): el tipo corre en `@MainActor` por el
//  aislamiento por defecto del proyecto, así publica `@Published` sin saltos de
//  actor. El bucle de recepción, el ping y la reconexión son `Task`s que usan
//  `async/await` sobre `URLSessionWebSocketTask` — sin DispatchQueue, sin
//  completion handlers, sin Timer.
//

import Foundation
import Combine
import CoreGraphics
import ImageIO
import os

@MainActor
final class WebSocketService: ObservableObject {

    /// Estado de la conexión, espejo del `connectionStatus` del frontend.
    enum ConnectionStatus: Sendable, Equatable {
        case disconnected
        case connecting
        case connected
    }

    // MARK: Estado publicado

    @Published private(set) var connectionStatus: ConnectionStatus = .disconnected
    @Published private(set) var backendReady = false
    /// Último frame anotado decodificado desde el mensaje `frame`.
    @Published private(set) var lastFrame: CGImage?

    /// Flujo de todos los mensajes entrantes parseados, para que los ViewModels
    /// reaccionen (accidentes, progreso, fin de procesado…).
    let messages: AsyncStream<WebSocketMessage>
    private let messagesContinuation: AsyncStream<WebSocketMessage>.Continuation

    // MARK: Dependencias y configuración

    private let session: URLSession
    private let pingInterval: Duration
    private let logger = Logger(subsystem: "com.adstudios.CrashCar-MacUI", category: "WebSocket")

    // MARK: Estado interno

    private var task: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var pingTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?

    private var url: URL?
    private var shouldReconnect = false
    private var reconnectAttempts = 0

    init(session: URLSession = .shared, pingInterval: Duration = .seconds(30)) {
        self.session = session
        self.pingInterval = pingInterval

        var continuation: AsyncStream<WebSocketMessage>.Continuation!
        self.messages = AsyncStream(bufferingPolicy: .unbounded) { continuation = $0 }
        self.messagesContinuation = continuation
    }

    // MARK: - API pública

    /// Abre la conexión al WebSocket y habilita la reconexión automática.
    func connect(to url: URL) {
        self.url = url
        shouldReconnect = true
        reconnectAttempts = 0
        openConnection()
    }

    /// Cierra la conexión y desactiva la reconexión.
    func disconnect() {
        shouldReconnect = false
        reconnectTask?.cancel()
        pingTask?.cancel()
        receiveTask?.cancel()
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        connectionStatus = .disconnected
        backendReady = false
    }

    /// Envía un mensaje saliente (`ping` / `processVideo`). No-op si no hay
    /// conexión activa.
    func send(_ message: WebSocketMessage) {
        guard let task else {
            logger.error("send: sin conexión activa")
            return
        }
        let data: Data
        do {
            data = try message.encoded()
        } catch {
            logger.error("send: fallo al serializar — \(error.localizedDescription)")
            return
        }
        let text = String(decoding: data, as: UTF8.self)
        Task {
            do {
                try await task.send(.string(text))
            } catch {
                logger.error("send: fallo de transporte — \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Reconexión (backoff como `handleWebSocketClose` del frontend)

    /// Delay de reconexión para un código de cierre: 3 s para el cierre anormal
    /// 1006, 1 s para cualquier otro — idéntico al `page.tsx`.
    static func reconnectDelay(forCloseCode code: Int) -> TimeInterval {
        code == 1006 ? 3.0 : 1.0
    }

    /// Mapea una secuencia de códigos de cierre a sus delays de reconexión.
    static func reconnectDelays(for closeCodes: [Int]) -> [TimeInterval] {
        closeCodes.map(reconnectDelay(forCloseCode:))
    }

    // MARK: - Decodificación de frames

    /// Decodifica un JPEG en base64 (campo `frame`) a `CGImage`.
    ///
    /// `nonisolated`: función pura sin estado de actor; la decodificación no debe
    /// quedar atada al MainActor (se invoca por frame en el hot-path de render).
    nonisolated static func decodeFrame(base64: String) throws -> CGImage {
        guard let data = Data(base64Encoded: base64) else {
            throw WebSocketMessageError.invalidBase64
        }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw WebSocketMessageError.frameDecodeFailed
        }
        return image
    }

    // MARK: - Conexión interna

    private func openConnection() {
        guard let url else { return }
        reconnectTask?.cancel()
        connectionStatus = .connecting

        let task = session.webSocketTask(with: url)
        self.task = task
        task.resume()

        startReceiveLoop()
        startPing()
    }

    private func startReceiveLoop() {
        receiveTask?.cancel()
        receiveTask = Task { [weak self] in
            await self?.receiveLoop()
        }
    }

    private func receiveLoop() async {
        guard let task else { return }
        while !Task.isCancelled {
            do {
                let message = try await task.receive()
                if connectionStatus != .connected {
                    connectionStatus = .connected
                    reconnectAttempts = 0
                }
                handle(message)
            } catch {
                handleClose(error: error)
                return
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        let data: Data
        switch message {
        case .string(let text):
            guard let utf8 = text.data(using: .utf8) else { return }
            data = utf8
        case .data(let raw):
            data = raw
        @unknown default:
            return
        }

        do {
            let parsed = try WebSocketMessage(data: data)
            process(parsed)
        } catch {
            logger.error("parse: \(error.localizedDescription)")
        }
    }

    private func process(_ message: WebSocketMessage) {
        switch message {
        case .ready:
            backendReady = true
        case let .frame(base64, _):
            if let image = try? Self.decodeFrame(base64: base64) {
                lastFrame = image
            }
        case .processingComplete:
            // El procesado terminó: no reconectar si el socket se cierra ahora.
            shouldReconnect = false
        default:
            break
        }
        messagesContinuation.yield(message)
    }

    private func startPing() {
        pingTask?.cancel()
        pingTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: self.pingInterval)
                if Task.isCancelled { break }
                self.send(.ping)
            }
        }
    }

    private func handleClose(error: Error) {
        connectionStatus = .disconnected
        backendReady = false
        pingTask?.cancel()
        logger.info("socket cerrado: \(error.localizedDescription)")

        guard shouldReconnect, url != nil else { return }

        let code = currentCloseCode()
        let delay = Self.reconnectDelay(forCloseCode: code)
        reconnectAttempts += 1
        logger.info("reconnect en \(delay)s (code \(code), intento \(self.reconnectAttempts))")

        reconnectTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard let self, !Task.isCancelled, self.shouldReconnect else { return }
            self.openConnection()
        }
    }

    /// Código de cierre efectivo: el del `closeCode` del task si fue un cierre
    /// limpio; 1006 (cierre anormal) si el socket se cayó sin código, como hace
    /// el navegador.
    private func currentCloseCode() -> Int {
        if let raw = task?.closeCode.rawValue, raw != 0 {
            return raw
        }
        return 1006
    }
}
