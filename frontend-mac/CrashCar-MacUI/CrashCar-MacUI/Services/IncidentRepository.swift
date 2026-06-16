//
//  IncidentRepository.swift
//  CrashCar-MacUI
//
//  Sesión 7 — Abstracción del acceso a datos de incidentes sobre Amplify Data
//  Gen 2 (AppSync/DynamoDB vía `AWSAPIPlugin`).
//
//  El plan original hablaba de `DataStore.observe`, pero este proyecto NO usa
//  `AWSDataStorePlugin`: persiste vía GraphQL (`Amplify.API`). Este protocolo
//  encapsula esas llamadas para que `IncidentViewModel` sea testeable con un
//  mock en memoria, sin red ni AWS.
//

import Foundation
import Amplify
import AWSPluginsCore

/// Operaciones de persistencia de incidentes. Inyectable para poder sustituir la
/// implementación real (`AmplifyIncidentRepository`) por un mock en los tests.
@MainActor
protocol IncidentRepository {
    /// Lista incidentes, opcionalmente filtrando por estado de verificación.
    func list(status: IncidentVerificationStatus?) async throws -> [Incident]
    /// Obtiene un incidente por id, o `nil` si no existe.
    func get(id: String) async throws -> Incident?
    /// Crea un incidente y devuelve el persistido.
    func create(_ incident: Incident) async throws -> Incident
    /// Actualiza un incidente y devuelve el persistido.
    func update(_ incident: Incident) async throws -> Incident
    /// Stream de incidentes recién creados (`onCreate`).
    func observeCreations() -> AsyncStream<Incident>
}

/// Implementación real contra AppSync/DynamoDB vía `Amplify.API` (GraphQL),
/// autorizada con Cognito User Pools.
struct AmplifyIncidentRepository: IncidentRepository {

    private let authMode: AWSAuthorizationType

    init(authMode: AWSAuthorizationType = .amazonCognitoUserPools) {
        self.authMode = authMode
    }

    func list(status: IncidentVerificationStatus?) async throws -> [Incident] {
        let request: GraphQLRequest<List<Incident>>
        if let status {
            request = .list(Incident.self,
                            where: Incident.keys.verificationStatus == status.rawValue,
                            authMode: authMode)
        } else {
            request = .list(Incident.self, authMode: authMode)
        }
        let result = try await Amplify.API.query(request: request)
        return try result.get().elements
    }

    func get(id: String) async throws -> Incident? {
        let result = try await Amplify.API.query(
            request: .get(Incident.self, byId: id, authMode: authMode)
        )
        return try result.get()
    }

    func create(_ incident: Incident) async throws -> Incident {
        try await mutate(.create(incident, authMode: authMode))
    }

    func update(_ incident: Incident) async throws -> Incident {
        try await mutate(.update(incident, authMode: authMode))
    }

    func observeCreations() -> AsyncStream<Incident> {
        let subscription = Amplify.API.subscribe(
            request: .subscription(of: Incident.self, type: .onCreate, authMode: authMode)
        )
        return AsyncStream { continuation in
            let task = Task {
                do {
                    for try await event in subscription {
                        switch event {
                        case .connection:
                            continue
                        case .data(let result):
                            if case .success(let incident) = result {
                                continuation.yield(incident)
                            }
                        }
                    }
                } catch {
                    Amplify.Logging.error("Suscripción onCreate Incident terminó: \(error)")
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // Patrón `mutate` deliberadamente duplicado con `AmplifyTrafficAidRepository`:
    // extraer un `AmplifyRepository<M: Model>` genérico se evaluó y descartó —
    // el riesgo de tocar la capa de datos supera el ahorro de ~3 líneas (DRY no
    // justifica el acoplamiento). No "unificar" sin reconsiderar esa decisión.
    private func mutate(_ request: GraphQLRequest<Incident>) async throws -> Incident {
        let result = try await Amplify.API.mutate(request: request)
        return try result.get()
    }
}
