//
//  EndToEndTests.swift
//  CrashCar-MacUITests
//
//  Sesión 12 — Suite de integración E2E contra AWS dev REAL (AppSync/DynamoDB/S3).
//
//  Cubre lo que NO requiere el login federado interactivo de Google: ejercita el
//  CRUD autenticado de incidentes y puestos de ayuda vial a través de los
//  repositorios Amplify reales y los ViewModels de producción. El flujo completo
//  con login Google + FastAPI se verifica con `frontend-mac/E2E_CHECKLIST.md`.
//
//  Gating: la suite SOLO corre si la variable de entorno `RUN_E2E=1` está puesta,
//  para que un `⌘U` ciego (sin `npx ampx sandbox` activo) no falle. Requiere
//  además un usuario nativo de Cognito de pruebas en las variables
//  `E2E_USERNAME` / `E2E_PASSWORD` (NO Google: un host de tests no puede iniciar
//  la sesión federada interactiva).
//
//  Prerrequisitos para ejecutarla:
//    1. `cd frontend-mac && npx ampx sandbox` (stack dev desplegado y alcanzable)
//    2. Un usuario de prueba en el User Pool con contraseña permanente
//    3. Esquema de ejecución con env: RUN_E2E=1, E2E_USERNAME=…, E2E_PASSWORD=…
//

import XCTest
import Amplify
import AWSPluginsCore
@testable import CrashCar_MacUI

@MainActor
final class EndToEndTests: XCTestCase {

    private let incidentRepo = AmplifyIncidentRepository()
    private let trafficRepo = AmplifyTrafficAidRepository()

    /// Ids creados durante un test, para limpiarlos en `tearDown` aunque falle.
    private var createdIncidentIds: [String] = []
    private var createdPostIds: [String] = []

    // MARK: - Ciclo de vida

    override func setUp() async throws {
        try XCTSkipUnless(Self.e2eEnabled,
                          "E2E deshabilitado. Exporta RUN_E2E=1 + E2E_USERNAME/E2E_PASSWORD y ten `npx ampx sandbox` activo.")
        try await signInTestUser()
    }

    override func tearDown() async throws {
        // Limpieza best-effort: borrar lo creado para no dejar basura en dev.
        for id in createdPostIds {
            try? await trafficRepo.delete(id: id)
        }
        for id in createdIncidentIds {
            if var incident = try? await incidentRepo.get(id: id) {
                // Los incidentes no exponen delete en el repo; se marca resuelto
                // como señal de dato de test (cleanup real lo hace el script de dev).
                incident.notes = "E2E_TEST_CLEANUP"
                _ = try? await incidentRepo.update(incident)
            }
        }
        createdPostIds.removeAll()
        createdIncidentIds.removeAll()
        await AmplifyAuthService().signOut()
    }

    // MARK: - TrafficAid CRUD end-to-end

    func testTrafficAidRoundTrip() async throws {
        let vm = TrafficAidViewModel(repository: trafficRepo)

        let post = try await vm.createPost(TrafficAidFormData(
            name: "E2E Test Post",
            address: "Av. Test 123",
            latitude: -2.17, longitude: -79.92,
            contactNumber: "0991234567",
            hasPoliceService: true))
        createdPostIds.append(post.id)

        let fetched = try await vm.fetchPost(id: post.id)
        XCTAssertEqual(fetched?.name, "E2E Test Post")

        try await vm.deletePost(post.id)
        createdPostIds.removeAll { $0 == post.id }
        let gone = try await vm.fetchPost(id: post.id)
        XCTAssertNil(gone, "El puesto debería haberse borrado de DynamoDB.")
    }

    // MARK: - Incidente: creación → verificación

    func testIncidentCreateThenVerify() async throws {
        let vm = IncidentViewModel(repository: incidentRepo)

        let id = try await vm.createIncident(from: DetectionPayload(
            confidenceScore: 0.93,
            accidentType: "car_car_accident",
            location: "-2.17, -79.92",
            latitude: -2.17, longitude: -79.92))
        createdIncidentIds.append(id)
        XCTAssertFalse(id.isEmpty)

        try await vm.verifyIncident(id,
                                    status: .approved,
                                    type: .vehicleCollision,
                                    severity: .major,
                                    notes: "E2E integration",
                                    responseNeeded: false)

        let updated = try await vm.fetchIncident(id: id)
        XCTAssertEqual(updated?.verificationStatus, .approved)
        XCTAssertNotNil(updated?.verifiedAt)
    }

    // MARK: - Incidente: listado por estado

    func testIncidentAppearsInPending() async throws {
        let vm = IncidentViewModel(repository: incidentRepo)

        let id = try await vm.createIncident(from: DetectionPayload(
            confidenceScore: 0.88,
            accidentType: "car_person_accident",
            location: "-2.17, -79.92"))
        createdIncidentIds.append(id)

        let pending = try await vm.fetchIncidents(status: .pending)
        XCTAssertTrue(pending.contains { $0.id == id },
                      "El incidente recién creado debería aparecer en pending.")
    }

    // MARK: - Helpers

    private static var e2eEnabled: Bool {
        let env = ProcessInfo.processInfo.environment
        return env["RUN_E2E"] == "1"
            && env["E2E_USERNAME"] != nil
            && env["E2E_PASSWORD"] != nil
    }

    /// Inicia sesión con el usuario nativo de Cognito de pruebas. Si ya hay sesión
    /// (de un test previo), la reutiliza.
    private func signInTestUser() async throws {
        if try await Amplify.Auth.fetchAuthSession().isSignedIn { return }
        let env = ProcessInfo.processInfo.environment
        guard let username = env["E2E_USERNAME"], let password = env["E2E_PASSWORD"] else {
            throw XCTSkip("Faltan credenciales E2E_USERNAME / E2E_PASSWORD.")
        }
        let result = try await Amplify.Auth.signIn(username: username, password: password)
        XCTAssertTrue(result.isSignedIn, "No se pudo iniciar sesión con el usuario de pruebas.")
    }
}
