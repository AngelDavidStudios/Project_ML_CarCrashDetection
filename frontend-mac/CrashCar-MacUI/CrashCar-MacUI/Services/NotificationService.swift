//
//  NotificationService.swift
//  CrashCar-MacUI
//
//  Sesión 11 — Notificaciones del sistema (macOS) cuando se detecta un accidente.
//
//  Pide permiso al arrancar, envía una alerta localizada por accidente y, al
//  tocar la notificación, abre la sección de incidentes en la app. El centro de
//  notificaciones se abstrae (`UserNotificationScheduling`) para testear el
//  payload sin tocar el sistema.
//
//  Concurrencia: el servicio es `@MainActor`; las operaciones del centro son
//  `async throws` (sin completion handlers). El coordinador del tap es un
//  `NSObject` (requisito de `UNUserNotificationCenterDelegate`).
//

import Foundation
import UserNotifications

// MARK: - Abstracción del centro de notificaciones

/// Operaciones del centro de notificaciones que usa el servicio. Inyectable para
/// testear el contenido de las notificaciones sin pedir permisos reales.
nonisolated protocol UserNotificationScheduling: Sendable {
    func requestAuthorization() async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
}

/// Implementación real sobre `UNUserNotificationCenter`.
nonisolated struct SystemNotificationCenter: UserNotificationScheduling {
    func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Notificación interna de navegación (tap → abrir incidente)

extension Notification.Name {
    /// Se emite cuando el usuario toca una notificación de accidente. `userInfo`
    /// lleva el `incidentId` bajo `NotificationService.incidentIdKey`.
    static let openIncidentRequested = Notification.Name("openIncidentRequested")
}

// MARK: - Servicio

@MainActor
final class NotificationService {

    /// Clave del id de incidente, tanto en el `userInfo` de la `UNNotification`
    /// como en la `Notification` interna de navegación. `nonisolated` para leerla
    /// desde el delegado del centro (contexto nonisolated).
    nonisolated static let incidentIdKey = "incidentId"

    static let shared = NotificationService()

    private let center: UserNotificationScheduling
    private let settings: AppSettings

    init(center: UserNotificationScheduling = SystemNotificationCenter(),
         settings: AppSettings) {
        self.center = center
        self.settings = settings
    }

    /// Conveniencia para la app real: usa `AppSettings.shared`. El cuerpo corre en
    /// MainActor, así que referenciar el singleton aquí no rompe el aislamiento
    /// (a diferencia de un valor por defecto, que se evalúa sin aislamiento).
    convenience init() {
        self.init(settings: .shared)
    }

    /// Pide permiso de notificaciones. Devuelve si fue concedido (los errores se
    /// tragan: la app funciona sin notificaciones).
    @discardableResult
    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization()) ?? false
    }

    /// Envía una alerta de accidente localizada al idioma seleccionado.
    func sendAccidentAlert(type: String,
                           location: String?,
                           confidence: Double,
                           incidentId: String? = nil) async {
        let loc = Localizer(language: settings.language)
        let percent = confidence.asPercent
        let typeLabel = Self.humanize(type)

        let content = UNMutableNotificationContent()
        content.title = loc.string("Accident detected")
        content.body = loc.format("%@ — %@ · %@ confidence",
                                  typeLabel, location ?? loc.string("Unknown"), percent)
        content.sound = .default
        if let incidentId {
            content.userInfo = [Self.incidentIdKey: incidentId]
        }

        let request = UNNotificationRequest(identifier: incidentId ?? UUID().uuidString,
                                            content: content,
                                            trigger: nil)
        try? await center.add(request)
    }

    /// Convierte la clase ML cruda (`car_car_accident`) en texto legible.
    private static func humanize(_ raw: String) -> String {
        raw.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - Coordinador del tap

/// Maneja el tap sobre una notificación reenviándolo como `Notification` interna
/// para que el shell abra la sección de incidentes. `NSObject` por el protocolo
/// del delegado. Se retiene en el `App`.
@MainActor
final class NotificationCoordinator: NSObject, UNUserNotificationCenterDelegate {

    /// Instala este coordinador como delegado del centro real.
    func install() {
        UNUserNotificationCenter.current().delegate = self
    }

    /// Muestra la notificación aun con la app en primer plano.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    /// El usuario tocó la notificación → emitir la solicitud de abrir el incidente.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let incidentId = userInfo[NotificationService.incidentIdKey] as? String
        await MainActor.run {
            NotificationCenter.default.post(
                name: .openIncidentRequested,
                object: nil,
                userInfo: incidentId.map { [NotificationService.incidentIdKey: $0] })
        }
    }
}
