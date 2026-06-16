//
//  MapAnnotationTests.swift
//  CrashCar-MacUITests
//
//  Sesión 8 — Lógica del `MapAnnotationBuilder`: color por severidad y exclusión
//  de incidentes sin coordenadas. Sin red ni MapKit.
//

import XCTest
import SwiftUI
import CoreLocation
import Amplify
@testable import CrashCar_MacUI

@MainActor
final class MapAnnotationTests: XCTestCase {

    func testIncidentAnnotationsGeneratedCorrectly() {
        let incidents = [
            makeIncident(lat: -2.17, lng: -79.92, severity: .critical),
            makeIncident(lat: -2.18, lng: -79.93, severity: .major),
        ]
        let annotations = MapAnnotationBuilder.annotations(from: incidents)

        XCTAssertEqual(annotations.count, 2)
        XCTAssertEqual(annotations[0].color, .red)
        XCTAssertEqual(annotations[1].color, .orange)
        XCTAssertEqual(annotations[0].kind, .incident)
    }

    func testMinorSeverityIsYellow() {
        let annotations = MapAnnotationBuilder.annotations(from: [
            makeIncident(lat: 0, lng: 0, severity: .minor)
        ])
        XCTAssertEqual(annotations.first?.color, .yellow)
    }

    func testIncidentsWithoutCoordinatesExcludedFromMap() {
        let incidents = [
            makeIncident(lat: nil, lng: nil, severity: .minor),
            makeIncident(lat: -2.17, lng: -79.92, severity: .major),
        ]
        let annotations = MapAnnotationBuilder.annotations(from: incidents)

        XCTAssertEqual(annotations.count, 1)
        XCTAssertEqual(annotations.first?.coordinate.latitude ?? 0, -2.17, accuracy: 0.0001)
    }

    func testTrafficAidPostsAreBlue() {
        let posts = [makeTrafficAidPost(lat: -2.2, lng: -79.9)]
        let annotations = MapAnnotationBuilder.annotations(from: posts)

        XCTAssertEqual(annotations.count, 1)
        XCTAssertEqual(annotations[0].color, .blue)
        XCTAssertEqual(annotations[0].kind, .trafficAid)
        XCTAssertEqual(annotations[0].title, "Test Post")
    }

    // MARK: - Helpers

    private func makeIncident(lat: Double?,
                              lng: Double?,
                              severity: IncidentSeverity?) -> Incident {
        Incident(detectedAt: Temporal.DateTime.now(),
                 latitude: lat,
                 longitude: lng,
                 confidenceScore: 0.9,
                 verificationStatus: .approved,
                 severity: severity,
                 responseNeeded: false,
                 responseInitiated: false)
    }

    private func makeTrafficAidPost(lat: Double, lng: Double) -> TrafficAidPost {
        TrafficAidPost(name: "Test Post",
                       address: "Av. Test 123",
                       latitude: lat,
                       longitude: lng,
                       contactNumber: "0991234567",
                       hasPoliceService: true,
                       hasAmbulance: false,
                       hasFireService: false,
                       operatingHours: "24/7",
                       status: "active")
    }
}
