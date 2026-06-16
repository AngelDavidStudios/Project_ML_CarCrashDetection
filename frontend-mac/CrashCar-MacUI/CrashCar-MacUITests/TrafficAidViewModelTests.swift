//
//  TrafficAidViewModelTests.swift
//  CrashCar-MacUITests
//
//  Sesión 9 — Lógica del `TrafficAidViewModel` sobre un `MockTrafficAidRepository`
//  en memoria: validación, actualización parcial y borrado. Sin red ni AWS.
//
//  Reemplaza el test de red `apiKey` de la Sesión 2 (retirado al quitar el apiKey
//  en la Sesión 6). El CRUD contra AWS real se cubre en la E2E de la Sesión 12.
//

import XCTest
import Amplify
@testable import CrashCar_MacUI

@MainActor
final class TrafficAidViewModelTests: XCTestCase {

    // MARK: - Validación

    func testCreateRequiredFieldsMissing() async {
        let vm = TrafficAidViewModel(repository: MockTrafficAidRepository())
        do {
            _ = try await vm.createPost(TrafficAidFormData(
                name: "", address: "test", latitude: 0, longitude: 0, contactNumber: ""))
            XCTFail("Debería lanzar error de validación")
        } catch let TrafficAidError.missingRequiredFields(fields) {
            XCTAssertTrue(fields.contains("name"))
            XCTAssertTrue(fields.contains("contactNumber"))
            XCTAssertFalse(fields.contains("address"))
        } catch {
            XCTFail("error inesperado: \(error)")
        }
    }

    func testCreateSucceedsWithValidData() async throws {
        let repo = MockTrafficAidRepository()
        let vm = TrafficAidViewModel(repository: repo)

        let post = try await vm.createPost(TrafficAidFormData(
            name: "Central Post", address: "Av. 9 de Octubre",
            latitude: -2.17, longitude: -79.92, contactNumber: "0991234567"))

        XCTAssertEqual(post.name, "Central Post")
        let all = try await vm.fetchPosts()
        XCTAssertEqual(all.count, 1)
    }

    // MARK: - Actualización

    func testUpdatePost() async throws {
        let post = makePost()
        let vm = TrafficAidViewModel(repository: MockTrafficAidRepository(posts: [post]))

        try await vm.updatePost(post.id, changes: TrafficAidChanges(name: "New Name"))

        let updated = try await vm.fetchPost(id: post.id)
        XCTAssertEqual(updated?.name, "New Name")
        XCTAssertNotEqual(updated?.updatedAt, post.updatedAt)
    }

    func testUpdateMissingPostThrows() async {
        let vm = TrafficAidViewModel(repository: MockTrafficAidRepository())
        do {
            try await vm.updatePost("nope", changes: TrafficAidChanges(name: "X"))
            XCTFail("esperaba notFound")
        } catch let TrafficAidError.notFound(id) {
            XCTAssertEqual(id, "nope")
        } catch {
            XCTFail("error inesperado: \(error)")
        }
    }

    // MARK: - Borrado

    func testDeletePost() async throws {
        let post = makePost()
        let vm = TrafficAidViewModel(repository: MockTrafficAidRepository(posts: [post]))

        try await vm.deletePost(post.id)

        let all = try await vm.fetchPosts()
        XCTAssertFalse(all.contains { $0.id == post.id })
    }

    // MARK: - Helpers

    private func makePost() -> TrafficAidPost {
        TrafficAidPost(name: "Test Post",
                       address: "Av. Test 123",
                       latitude: -2.17,
                       longitude: -79.92,
                       contactNumber: "0991234567",
                       hasPoliceService: true,
                       hasAmbulance: false,
                       hasFireService: false,
                       operatingHours: "24/7",
                       status: "active")
    }
}

// MARK: - Mock del repositorio

@MainActor
final class MockTrafficAidRepository: TrafficAidRepository {
    private(set) var store: [String: TrafficAidPost]

    init(posts: [TrafficAidPost] = []) {
        store = Dictionary(uniqueKeysWithValues: posts.map { ($0.id, $0) })
    }

    func list() async throws -> [TrafficAidPost] {
        Array(store.values)
    }

    func get(id: String) async throws -> TrafficAidPost? {
        store[id]
    }

    func create(_ post: TrafficAidPost) async throws -> TrafficAidPost {
        store[post.id] = post
        return post
    }

    func update(_ post: TrafficAidPost) async throws -> TrafficAidPost {
        // Simula el `updatedAt` gestionado por el servidor para que las pruebas
        // de cambio sean deterministas.
        var stored = post
        stored.updatedAt = Temporal.DateTime.now()
        store[post.id] = stored
        return stored
    }

    func delete(id: String) async throws {
        store[id] = nil
    }
}
