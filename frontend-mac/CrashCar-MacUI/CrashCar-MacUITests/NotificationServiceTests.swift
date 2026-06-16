//
//  NotificationServiceTests.swift
//  CrashCar-MacUITests
//
//  Sesión 11 — Verifica el contenido de la notificación de accidente (título,
//  cuerpo localizado, confianza, userInfo) con un centro de notificaciones mock.
//

import XCTest
import UserNotifications
@testable import CrashCar_MacUI

@MainActor
final class NotificationServiceTests: XCTestCase {

    func testAccidentAlertSpanishPayload() async {
        let center = MockNotificationCenter()
        let service = NotificationService(center: center, settings: settings(.es))

        await service.sendAccidentAlert(type: "car_car_accident",
                                        location: "Quito Norte",
                                        confidence: 0.95)

        XCTAssertEqual(center.added.count, 1)
        let content = center.added[0].content
        XCTAssertTrue(content.title.contains("Accidente"), content.title)
        XCTAssertTrue(content.body.contains("95%"), content.body)
        XCTAssertTrue(content.body.contains("Quito Norte"), content.body)
        XCTAssertTrue(content.body.contains("de confianza"), content.body)
    }

    func testAccidentAlertEnglishWithIncidentId() async {
        let center = MockNotificationCenter()
        let service = NotificationService(center: center, settings: settings(.en))

        await service.sendAccidentAlert(type: "car_person_accident",
                                        location: nil,
                                        confidence: 0.8,
                                        incidentId: "abc123")

        XCTAssertEqual(center.added.count, 1)
        let request = center.added[0]
        XCTAssertTrue(request.content.title.contains("Accident"), request.content.title)
        XCTAssertTrue(request.content.body.contains("80%"), request.content.body)
        // Sin ubicación → usa "Unknown" localizado (en inglés aquí).
        XCTAssertTrue(request.content.body.contains("Unknown"), request.content.body)
        XCTAssertEqual(request.identifier, "abc123")
        XCTAssertEqual(request.content.userInfo[NotificationService.incidentIdKey] as? String, "abc123")
    }

    func testRequestAuthorizationReflectsCenter() async {
        let denied = MockNotificationCenter(); denied.granted = false
        let service = NotificationService(center: denied, settings: settings(.en))
        let result = await service.requestAuthorization()
        XCTAssertFalse(result)
    }

    // MARK: - Helpers

    private func settings(_ language: AppLanguage) -> AppSettings {
        let defaults = UserDefaults(suiteName: "test.notif.\(UUID().uuidString)")!
        let settings = AppSettings(defaults: defaults)
        settings.language = language
        return settings
    }
}

// MARK: - Mock

final class MockNotificationCenter: UserNotificationScheduling, @unchecked Sendable {
    private(set) var added: [UNNotificationRequest] = []
    var granted = true

    func requestAuthorization() async throws -> Bool { granted }
    func add(_ request: UNNotificationRequest) async throws { added.append(request) }
}
