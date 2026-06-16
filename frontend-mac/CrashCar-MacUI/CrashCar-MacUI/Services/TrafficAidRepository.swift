//
//  TrafficAidRepository.swift
//  CrashCar-MacUI
//
//  Sesión 9 — Acceso a datos de puestos de ayuda vial sobre Amplify Data Gen 2
//  (AppSync/DynamoDB vía `AWSAPIPlugin`). Mismo patrón que `IncidentRepository`:
//  inyectable para testear el `TrafficAidViewModel` con un mock sin red.
//

import Foundation
import Amplify
import AWSPluginsCore

/// Operaciones de persistencia de puestos de ayuda vial.
@MainActor
protocol TrafficAidRepository {
    func list() async throws -> [TrafficAidPost]
    func get(id: String) async throws -> TrafficAidPost?
    func create(_ post: TrafficAidPost) async throws -> TrafficAidPost
    func update(_ post: TrafficAidPost) async throws -> TrafficAidPost
    func delete(id: String) async throws
}

/// Implementación real contra AppSync/DynamoDB vía `Amplify.API`, autorizada con
/// Cognito User Pools (grupo `Operators`).
struct AmplifyTrafficAidRepository: TrafficAidRepository {

    private let authMode: AWSAuthorizationType

    init(authMode: AWSAuthorizationType = .amazonCognitoUserPools) {
        self.authMode = authMode
    }

    func list() async throws -> [TrafficAidPost] {
        let result = try await Amplify.API.query(
            request: .list(TrafficAidPost.self, authMode: authMode)
        )
        return try result.get().elements
    }

    func get(id: String) async throws -> TrafficAidPost? {
        let result = try await Amplify.API.query(
            request: .get(TrafficAidPost.self, byId: id, authMode: authMode)
        )
        return try result.get()
    }

    func create(_ post: TrafficAidPost) async throws -> TrafficAidPost {
        try await mutate(.create(post, authMode: authMode))
    }

    func update(_ post: TrafficAidPost) async throws -> TrafficAidPost {
        try await mutate(.update(post, authMode: authMode))
    }

    func delete(id: String) async throws {
        guard let post = try await get(id: id) else { return }
        _ = try await mutate(.delete(post, authMode: authMode))
    }

    // Patrón `mutate` deliberadamente duplicado con `AmplifyIncidentRepository`
    // (ver nota allí): no extraer un repositorio genérico sin reconsiderar la
    // decisión de no acoplar la capa de datos.
    private func mutate(_ request: GraphQLRequest<TrafficAidPost>) async throws -> TrafficAidPost {
        let result = try await Amplify.API.mutate(request: request)
        return try result.get()
    }
}
