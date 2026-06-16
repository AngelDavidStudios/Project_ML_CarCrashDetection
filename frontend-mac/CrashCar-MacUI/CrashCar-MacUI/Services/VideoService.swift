//
//  VideoService.swift
//  CrashCar-MacUI
//
//  Sesión 6 — Selección y preparación de vídeos para el backend FastAPI.
//
//  El operador elige un vídeo local (`NSOpenPanel`); el servicio lo copia a un
//  directorio de trabajo y devuelve su ruta absoluta para que FastAPI lo lea.
//
//  Concurrencia (Approachable Concurrency): el tipo es `@MainActor` porque
//  `NSOpenPanel` vive en el main actor. La E/S de ficheros se ejecuta fuera del
//  main actor con `Task.detached` sobre helpers `nonisolated static` que no
//  capturan estado no-`Sendable` — sin DispatchQueue ni completion handlers.
//

import Foundation
import AppKit
import UniformTypeIdentifiers

@MainActor
final class VideoService {

    /// Directorio donde se copian los vídeos antes de procesarlos.
    let workspaceDir: URL

    /// `nonisolated` para poder usarse como valor por defecto de `init`/de otros
    /// inits (los defaults se evalúan sin aislamiento). Solo guarda una URL.
    nonisolated init(workspaceDir: URL = VideoService.defaultWorkspaceDir) {
        self.workspaceDir = workspaceDir
    }

    /// `~/Library/Application Support/CrashDetector/uploads/`.
    nonisolated static var defaultWorkspaceDir: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent("CrashDetector", isDirectory: true)
            .appendingPathComponent("uploads", isDirectory: true)
    }

    // MARK: - Selección

    /// Abre un `NSOpenPanel` para elegir un vídeo. Devuelve `nil` si se cancela.
    func pickVideo() -> URL? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .mpeg4Movie, .quickTimeMovie, .video]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = "Select"
        return panel.runModal() == .OK ? panel.url : nil
    }

    // MARK: - Preparación

    /// Crea el directorio de trabajo si no existe.
    func ensureWorkspaceDirExists() async throws {
        let dir = workspaceDir
        try await Task.detached(priority: .utility) {
            try Self.createDirectory(at: dir)
        }.value
    }

    /// Copia el vídeo al directorio de trabajo y devuelve la ruta absoluta del
    /// destino, legible por FastAPI. Sobrescribe si ya existía una copia previa.
    @discardableResult
    func prepareForFastAPI(url: URL) async throws -> String {
        try await ensureWorkspaceDirExists()

        let destination = workspaceDir.appendingPathComponent(Self.uniqueName(for: url))
        try await Task.detached(priority: .utility) {
            try Self.copyFile(from: url, to: destination)
        }.value

        return destination.path
    }

    // MARK: - Helpers de E/S (fuera del main actor)

    /// Nombre único conservando la extensión original, para evitar colisiones
    /// entre subidas sucesivas.
    private static func uniqueName(for url: URL) -> String {
        let stem = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        let token = UUID().uuidString.prefix(8)
        let safeStem = stem.isEmpty ? "video" : stem
        return ext.isEmpty ? "\(safeStem)_\(token)" : "\(safeStem)_\(token).\(ext)"
    }

    nonisolated private static func createDirectory(at url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    nonisolated private static func copyFile(from source: URL, to destination: URL) throws {
        // El vídeo elegido por NSOpenPanel es un recurso con security-scope bajo
        // App Sandbox; hay que abrir el acceso para poder leerlo.
        let scoped = source.startAccessingSecurityScopedResource()
        defer { if scoped { source.stopAccessingSecurityScopedResource() } }

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: source, to: destination)
    }
}
