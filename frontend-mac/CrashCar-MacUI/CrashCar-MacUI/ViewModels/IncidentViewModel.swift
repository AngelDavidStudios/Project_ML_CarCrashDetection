//
//  IncidentViewModel.swift
//  CrashCar-MacUI
//
//  Sesión 2 — CRUD de incidentes contra DynamoDB vía Amplify Data Gen 2.
//
//  Concurrencia: el tipo corre en `@MainActor` por el aislamiento por defecto
//  del proyecto (Approachable Concurrency). Todas las llamadas a `Amplify.API`
//  son `async throws` — sin DispatchQueue ni completion handlers.
//

import Foundation
import Combine
import Amplify
import AWSPluginsCore

/// Datos crudos de una detección de accidente (lo que llega por el WebSocket en
/// el evento `image_saved`). Se transforma en un `Incident` al persistirlo.
///
/// `Sendable` para poder cruzar dominios de aislamiento sin copias inseguras.
struct DetectionPayload: Sendable {
    var confidenceScore: Double
    var accidentType: String          // clase ML cruda, p. ej. "car_car_accident"
    var location: String?
    var latitude: Double?
    var longitude: Double?
    var imageUrl: String?
    var s3ImageKey: String?
    var detectedAt: Date

    init(confidenceScore: Double,
         accidentType: String,
         location: String? = nil,
         latitude: Double? = nil,
         longitude: Double? = nil,
         imageUrl: String? = nil,
         s3ImageKey: String? = nil,
         detectedAt: Date = Date()) {
        self.confidenceScore = confidenceScore
        self.accidentType = accidentType
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.imageUrl = imageUrl
        self.s3ImageKey = s3ImageKey
        self.detectedAt = detectedAt
    }
}

/// Errores de la capa de datos de incidentes. Los errores de transporte/GraphQL
/// se propagan tal cual (`GraphQLResponseError`, `APIError`) vía `try result.get()`.
enum IncidentError: Error {
    /// Se esperaba un incidente y no se encontró por id.
    case notFound(String)
}

@MainActor
final class IncidentViewModel: ObservableObject {

    /// Última lista cargada — la UI observa este array.
    @Published private(set) var incidents: [Incident] = []

    /// Acceso a datos. Inyectable para testear la lógica del VM sin red
    /// (ver `IncidentRepository` / `MockIncidentRepository`).
    private let repository: IncidentRepository

    init(repository: IncidentRepository) {
        self.repository = repository
    }

    /// Conveniencia para la app real: usa el repositorio Amplify. El cuerpo corre
    /// en MainActor, así que construir `AmplifyIncidentRepository` aquí evita el
    /// problema de los valores por defecto evaluados sin aislamiento.
    convenience init() {
        self.init(repository: AmplifyIncidentRepository())
    }

    // MARK: - Lecturas

    /// Lista incidentes, opcionalmente filtrando por estado de verificación.
    @discardableResult
    func fetchIncidents(status: IncidentVerificationStatus? = nil) async throws -> [Incident] {
        let items = try await repository.list(status: status)
        incidents = items
        return items
    }

    /// Obtiene un incidente por id (o `nil` si no existe).
    func fetchIncident(id: String) async throws -> Incident? {
        try await repository.get(id: id)
    }

    // MARK: - Escrituras

    /// Crea un incidente nuevo a partir de una detección. Devuelve su id.
    @discardableResult
    func createIncident(from payload: DetectionPayload) async throws -> String {
        let incident = Incident(
            detectedAt: Temporal.DateTime(payload.detectedAt),
            location: payload.location,
            latitude: payload.latitude,
            longitude: payload.longitude,
            confidenceScore: payload.confidenceScore,
            imageUrl: payload.imageUrl,
            s3ImageKey: payload.s3ImageKey,
            verificationStatus: .pending,
            notes: payload.accidentType,   // la clase ML cruda hasta que se verifica
            responseNeeded: false,
            responseInitiated: false
        )

        let created = try await repository.create(incident)
        return created.id
    }

    /// Verifica un incidente: fija estado, tipo, severidad, notas y `verifiedAt`.
    @discardableResult
    func verifyIncident(_ id: String,
                        status: IncidentVerificationStatus,
                        type: IncidentIncidentType?,
                        severity: IncidentSeverity?,
                        notes: String?,
                        responseNeeded: Bool) async throws -> Incident {
        guard var incident = try await repository.get(id: id) else {
            throw IncidentError.notFound(id)
        }
        incident.verificationStatus = status
        incident.incidentType = type
        incident.severity = severity
        incident.notes = notes
        incident.responseNeeded = responseNeeded
        incident.verifiedAt = Temporal.DateTime.now()
        return try await repository.update(incident)
    }

    /// Marca el incidente como resuelto, registrando `resolvedAt`.
    @discardableResult
    func resolveIncident(_ id: String, notes: String?) async throws -> Incident {
        guard var incident = try await repository.get(id: id) else {
            throw IncidentError.notFound(id)
        }
        incident.resolvedAt = Temporal.DateTime.now()
        if let notes { incident.notes = notes }
        return try await repository.update(incident)
    }

    /// Marca que la respuesta de emergencia se ha iniciado.
    @discardableResult
    func initiateResponse(for id: String) async throws -> Incident {
        guard var incident = try await repository.get(id: id) else {
            throw IncidentError.notFound(id)
        }
        incident.responseInitiated = true
        return try await repository.update(incident)
    }

    // MARK: - Realtime

    /// Stream de incidentes recién creados (`onCreate`). El consumidor itera con
    /// `for await incident in vm.observeNewIncidents() { ... }`.
    func observeNewIncidents() -> AsyncStream<Incident> {
        repository.observeCreations()
    }
}
