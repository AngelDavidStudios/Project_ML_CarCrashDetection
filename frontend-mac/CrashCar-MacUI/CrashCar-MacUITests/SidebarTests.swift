//
//  SidebarTests.swift
//  CrashCar-MacUITests
//
//  Sesión 4 — Tests del shell: presencia de las secciones navegables y
//  persistencia de la preferencia de idioma.
//
//  Nota: el plan original mencionaba un toggle dark/light, pero la Sesión 4
//  (paso 4) lo descarta — macOS 26 gestiona el tema del sistema y LiquidGlass se
//  adapta solo. La preferencia persistente es el idioma EN/ES.
//

import XCTest
import SwiftUI
@testable import CrashCar_MacUI

@MainActor
final class SidebarTests: XCTestCase {

    func testAllSectionsPresent() {
        let sidebar = SidebarView(selection: .constant(.detection))
        let sections = sidebar.sections
        XCTAssertEqual(sections.count, 4)
        XCTAssertTrue(sections.contains(.detection))
        XCTAssertTrue(sections.contains(.pendingVerification))
        XCTAssertTrue(sections.contains(.ongoingIncidents))
        XCTAssertTrue(sections.contains(.trafficAid))
    }

    func testSectionsGroupedLikeNextJsSidebar() {
        XCTAssertEqual(AppSection.detection.group, .detection)
        XCTAssertEqual(AppSection.pendingVerification.group, .incident)
        XCTAssertEqual(AppSection.ongoingIncidents.group, .incident)
        XCTAssertEqual(AppSection.trafficAid.group, .traffic)
    }

    func testLanguagePreferenceDefaultsToEnglish() {
        let defaults = isolatedDefaults()
        let settings = AppSettings(defaults: defaults)
        XCTAssertEqual(settings.language, .en)
    }

    func testLanguagePreferencePersists() {
        let defaults = isolatedDefaults()

        let settings = AppSettings(defaults: defaults)
        settings.language = .es

        // Una instancia nueva sobre el mismo store recupera el valor persistido,
        // simulando un reinicio de la app.
        let reloaded = AppSettings(defaults: defaults)
        XCTAssertEqual(reloaded.language, .es)
    }

    /// `UserDefaults` con un dominio aislado para no contaminar `.standard`.
    private func isolatedDefaults() -> UserDefaults {
        let suite = "SidebarTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
