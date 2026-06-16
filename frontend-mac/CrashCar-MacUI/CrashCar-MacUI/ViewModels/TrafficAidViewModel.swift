//
//  TrafficAidViewModel.swift
//  CrashCar-MacUI
//
//  Sesión 2 — CRUD de puestos de ayuda vial contra DynamoDB vía Amplify Data Gen 2.
//  Sesión 9 — Refactor a `TrafficAidRepository` inyectable + validación de
//  campos requeridos + actualización parcial. CRUD completo con paridad Next.js.
//

import Foundation
import Combine
import Amplify

/// Errores de la capa de datos de puestos de ayuda vial. Los errores de
/// transporte/GraphQL se propagan tal cual vía el repositorio.
enum TrafficAidError: Error, Equatable {
    case notFound(String)
    /// Faltan campos requeridos (lista de nombres de campo).
    case missingRequiredFields([String])
}

/// Datos del formulario de creación/edición de un puesto de ayuda vial.
struct TrafficAidFormData: Sendable {
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var contactNumber: String
    var hasPoliceService: Bool = false
    var hasAmbulance: Bool = false
    var hasFireService: Bool = false
    var operatingHours: String = "24/7"
    var additionalInfo: String = ""
    var status: String = "active"

    /// Nombres de los campos requeridos que están vacíos.
    func missingRequiredFields() -> [String] {
        var missing: [String] = []
        if name.trimmed.isEmpty { missing.append("name") }
        if address.trimmed.isEmpty { missing.append("address") }
        if contactNumber.trimmed.isEmpty { missing.append("contactNumber") }
        return missing
    }
}

/// Cambios parciales para actualizar un puesto: solo se aplican los no-`nil`.
struct TrafficAidChanges: Sendable {
    var name: String?
    var address: String?
    var latitude: Double?
    var longitude: Double?
    var contactNumber: String?
    var hasPoliceService: Bool?
    var hasAmbulance: Bool?
    var hasFireService: Bool?
    var operatingHours: String?
    var additionalInfo: String?
    var status: String?

    func apply(to post: inout TrafficAidPost) {
        if let name { post.name = name }
        if let address { post.address = address }
        if let latitude { post.latitude = latitude }
        if let longitude { post.longitude = longitude }
        if let contactNumber { post.contactNumber = contactNumber }
        if let hasPoliceService { post.hasPoliceService = hasPoliceService }
        if let hasAmbulance { post.hasAmbulance = hasAmbulance }
        if let hasFireService { post.hasFireService = hasFireService }
        if let operatingHours { post.operatingHours = operatingHours }
        if let additionalInfo { post.additionalInfo = additionalInfo }
        if let status { post.status = status }
    }
}

@MainActor
final class TrafficAidViewModel: ObservableObject {

    /// Última lista cargada — la UI observa este array.
    @Published private(set) var posts: [TrafficAidPost] = []

    private let repository: TrafficAidRepository

    init(repository: TrafficAidRepository) {
        self.repository = repository
    }

    /// Conveniencia para la app real (repositorio Amplify), construido en cuerpo
    /// MainActor para evitar el problema de los defaults sin aislamiento.
    convenience init() {
        self.init(repository: AmplifyTrafficAidRepository())
    }

    // MARK: - Lecturas

    @discardableResult
    func fetchPosts() async throws -> [TrafficAidPost] {
        let items = try await repository.list()
        posts = items
        return items
    }

    func fetchPost(id: String) async throws -> TrafficAidPost? {
        try await repository.get(id: id)
    }

    // MARK: - Escrituras

    /// Crea un puesto validando los campos requeridos.
    @discardableResult
    func createPost(_ data: TrafficAidFormData) async throws -> TrafficAidPost {
        let missing = data.missingRequiredFields()
        guard missing.isEmpty else {
            throw TrafficAidError.missingRequiredFields(missing)
        }
        let post = TrafficAidPost(
            name: data.name,
            address: data.address,
            latitude: data.latitude,
            longitude: data.longitude,
            contactNumber: data.contactNumber,
            hasPoliceService: data.hasPoliceService,
            hasAmbulance: data.hasAmbulance,
            hasFireService: data.hasFireService,
            operatingHours: data.operatingHours,
            additionalInfo: data.additionalInfo.trimmed.isEmpty ? nil : data.additionalInfo,
            status: data.status)
        return try await repository.create(post)
    }

    /// Actualiza un puesto aplicando solo los cambios indicados.
    @discardableResult
    func updatePost(_ id: String, changes: TrafficAidChanges) async throws -> TrafficAidPost {
        guard var post = try await repository.get(id: id) else {
            throw TrafficAidError.notFound(id)
        }
        changes.apply(to: &post)
        return try await repository.update(post)
    }

    func deletePost(_ id: String) async throws {
        try await repository.delete(id: id)
    }
}
