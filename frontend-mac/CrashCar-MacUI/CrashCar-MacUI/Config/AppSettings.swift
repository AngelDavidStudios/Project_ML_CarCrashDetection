//
//  AppSettings.swift
//  CrashCar-MacUI
//
//  Sesión 4 — Preferencias de la app persistidas en UserDefaults.
//
//  No hay toggle dark/light: macOS 26 (Tahoe) gestiona el tema del sistema y
//  LiquidGlass se adapta automáticamente (ver MIGRATION_SWIFT.md, Sesión 4, paso 4).
//  La única preferencia por ahora es el idioma EN/ES; el cableado real de
//  localización (String Catalog) llega en la Sesión 11.
//

import Foundation
import Combine

/// Idioma de la interfaz. El `rawValue` coincide con el código de locale.
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case en
    case es

    var id: String { rawValue }

    /// Nombre del idioma en su propia lengua, para el selector.
    var displayName: String {
        switch self {
        case .en: "English"
        case .es: "Español"
        }
    }
}

/// Preferencias persistentes de la app. Inyectable (`defaults`) para poder
/// testear la persistencia con un dominio aislado.
@MainActor
final class AppSettings: ObservableObject {

    /// Instancia compartida usada por la app (respaldada por `.standard`).
    static let shared = AppSettings()

    private let defaults: UserDefaults
    private let languageKey = "app.language"
    private let backendURLKey = "app.backendWebSocketURL"

    /// Endpoint por defecto del WebSocket de detección del backend FastAPI.
    /// `nonisolated` para poder leerlo desde defaults de inits sin aislamiento.
    nonisolated static let defaultBackendURLString = "ws://localhost:8000/ws/detect"

    /// Idioma seleccionado. Se persiste al cambiar.
    @Published var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: languageKey) }
    }

    /// URL del WebSocket de detección (`/ws/detect`). Configurable para apuntar a
    /// un backend remoto; por defecto el local de desarrollo.
    @Published var backendURLString: String {
        didSet { defaults.set(backendURLString, forKey: backendURLKey) }
    }

    /// `backendURLString` como `URL`, con fallback al default si fuese inválida.
    var backendWebSocketURL: URL {
        URL(string: backendURLString)
            ?? URL(string: AppSettings.defaultBackendURLString)!
    }

    /// Base HTTP del backend, derivada de la URL del WebSocket (`ws→http`,
    /// `wss→https`). Sirve para resolver las imágenes de accidentes que el backend
    /// expone como estáticas (`/accident_images/<file>`) hasta que se migren a S3
    /// en la Sesión 10.
    var backendHTTPBaseURL: URL {
        let ws = backendWebSocketURL
        var components = URLComponents(url: ws, resolvingAgainstBaseURL: false)
        components?.scheme = (ws.scheme == "wss") ? "https" : "http"
        components?.path = ""
        return components?.url ?? URL(string: "http://localhost:8000")!
    }

    /// Directorio de trabajo donde se copian los vídeos para que FastAPI los lea.
    /// `~/Library/Application Support/CrashDetector/uploads/`.
    var workspaceUploadsDir: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent("CrashDetector", isDirectory: true)
            .appendingPathComponent("uploads", isDirectory: true)
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.string(forKey: languageKey)
        self.language = stored.flatMap(AppLanguage.init(rawValue:)) ?? .en
        self.backendURLString = defaults.string(forKey: backendURLKey)
            ?? AppSettings.defaultBackendURLString
    }
}
