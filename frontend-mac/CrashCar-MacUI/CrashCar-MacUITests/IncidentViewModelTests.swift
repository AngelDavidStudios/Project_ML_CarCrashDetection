//
//  IncidentViewModelTests.swift
//  CrashCar-MacUITests
//
//  Sesión 7 — Lógica del `IncidentViewModel` sobre un `MockIncidentRepository`
//  en memoria: sin red ni AWS.
//
//  Reemplaza los tests de red `apiKey` de la Sesión 2 (retirados al quitar el
//  apiKey en la Sesión 6). La cobertura de CRUD contra AWS real se hará en la
//  suite de integración E2E de la Sesión 12.
//

import XCTest
import Amplify
@testable import CrashCar_MacUI

@MainActor
final class IncidentViewModelTests: XCTestCase {

    // MARK: - Filtro por estado

    func testFilterByStatusPending() async throws {
        let repo = MockIncidentRepository(incidents: [
            makeIncident(status: .pending),
            makeIncident(status: .approved),
            makeIncident(status: .rejected),
            makeIncident(status: .pending),
        ])
        let vm = IncidentViewModel(repository: repo)

        let pending = try await vm.fetchIncidents(status: .pending)

        XCTAssertEqual(pending.count, 2)
        XCTAssertTrue(pending.allSatisfy { $0.verificationStatus == .pending })
        // El array publicado refleja lo último cargado.
        XCTAssertEqual(vm.incidents.count, 2)
    }

    // MARK: - Transiciones de verificación

    func testVerifyTransitionToApproved() async throws {
        let pending = makeIncident(status: .pending)
        let vm = IncidentViewModel(repository: MockIncidentRepository(incidents: [pending]))

        try await vm.verifyIncident(pending.id,
                                    status: .approved,
                                    type: .vehicleCollision,
                                    severity: .critical,
                                    notes: "Verified",
                                    responseNeeded: true)

        let updated = try await vm.fetchIncident(id: pending.id)
        XCTAssertEqual(updated?.verificationStatus, .approved)
        XCTAssertNotNil(updated?.verifiedAt)
        XCTAssertEqual(updated?.incidentType, .vehicleCollision)
        XCTAssertEqual(updated?.severity, .critical)
        XCTAssertEqual(updated?.responseNeeded, true)
    }

    func testRejectTransition() async throws {
        let pending = makeIncident(status: .pending)
        let vm = IncidentViewModel(repository: MockIncidentRepository(incidents: [pending]))

        try await vm.verifyIncident(pending.id,
                                    status: .rejected,
                                    type: nil,
                                    severity: nil,
                                    notes: "False alarm",
                                    responseNeeded: false)

        let updated = try await vm.fetchIncident(id: pending.id)
        XCTAssertEqual(updated?.verificationStatus, .rejected)
        XCTAssertEqual(updated?.notes, "False alarm")
    }

    func testVerifyMissingIncidentThrows() async {
        let vm = IncidentViewModel(repository: MockIncidentRepository())
        do {
            try await vm.verifyIncident("does-not-exist",
                                        status: .approved, type: nil, severity: nil,
                                        notes: nil, responseNeeded: false)
            XCTFail("esperaba IncidentError.notFound")
        } catch let IncidentError.notFound(id) {
            XCTAssertEqual(id, "does-not-exist")
        } catch {
            XCTFail("error inesperado: \(error)")
        }
    }

    // MARK: - Creación / respuesta / resolución

    func testCreateIncidentFromPayload() async throws {
        let repo = MockIncidentRepository()
        let vm = IncidentViewModel(repository: repo)

        let id = try await vm.createIncident(from: DetectionPayload(
            confidenceScore: 0.92,
            accidentType: "car_car_accident",
            location: "-2.17, -79.92"))

        XCTAssertFalse(id.isEmpty)
        let created = try await vm.fetchIncident(id: id)
        XCTAssertEqual(created?.verificationStatus, .pending)
        XCTAssertEqual(created?.notes, "car_car_accident")
    }

    func testInitiateResponseSetsFlag() async throws {
        let approved = makeIncident(status: .approved)
        let vm = IncidentViewModel(repository: MockIncidentRepository(incidents: [approved]))

        try await vm.initiateResponse(for: approved.id)

        let updated = try await vm.fetchIncident(id: approved.id)
        XCTAssertEqual(updated?.responseInitiated, true)
    }

    func testResolveSetsResolvedAt() async throws {
        let approved = makeIncident(status: .approved)
        let vm = IncidentViewModel(repository: MockIncidentRepository(incidents: [approved]))

        try await vm.resolveIncident(approved.id, notes: "Cleared")

        let updated = try await vm.fetchIncident(id: approved.id)
        XCTAssertNotNil(updated?.resolvedAt)
        XCTAssertEqual(updated?.notes, "Cleared")
    }

    // MARK: - Helpers

    private func makeIncident(id: String = UUID().uuidString,
                              status: IncidentVerificationStatus = .pending,
                              severity: IncidentSeverity? = nil) -> Incident {
        Incident(id: id,
                 detectedAt: Temporal.DateTime.now(),
                 confidenceScore: 0.9,
                 verificationStatus: status,
                 severity: severity,
                 responseNeeded: false,
                 responseInitiated: false)
    }
}

// MARK: - Mock del repositorio

@MainActor
final class MockIncidentRepository: IncidentRepository {
    private(set) var store: [String: Incident]

    init(incidents: [Incident] = []) {
        store = Dictionary(uniqueKeysWithValues: incidents.map { ($0.id, $0) })
    }

    func list(status: IncidentVerificationStatus?) async throws -> [Incident] {
        let all = Array(store.values)
        guard let status else { return all }
        return all.filter { $0.verificationStatus == status }
    }

    func get(id: String) async throws -> Incident? { store[id] }

    func create(_ incident: Incident) async throws -> Incident {
        store[incident.id] = incident
        return incident
    }

    func update(_ incident: Incident) async throws -> Incident {
        store[incident.id] = incident
        return incident
    }

    func observeCreations() -> AsyncStream<Incident> {
        AsyncStream { $0.finish() }
    }
}
