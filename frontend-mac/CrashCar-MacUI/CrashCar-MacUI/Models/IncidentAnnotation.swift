//
//  IncidentAnnotation.swift
//  CrashCar-MacUI
//
//  Sesión 8 — Anotaciones del mapa para incidentes activos y puestos de ayuda
//  vial, más el `MapAnnotationBuilder` (lógica pura, testeable sin MapKit/SwiftUI).
//

import SwiftUI
import CoreLocation

/// Un pin en el mapa: un incidente (color por severidad) o un puesto de ayuda
/// vial (azul). `Identifiable` para `Map`/`ForEach`.
struct IncidentAnnotation: Identifiable {
    enum Kind {
        case incident
        case trafficAid
    }

    let id: String
    let coordinate: CLLocationCoordinate2D
    let color: Color
    let title: String
    let subtitle: String
    let kind: Kind
}

/// Construye anotaciones a partir de los modelos de datos. Excluye los que no
/// tienen coordenadas y asigna color de pin por severidad (incidentes) o azul
/// (puestos de ayuda).
enum MapAnnotationBuilder {

    /// Color del pin de incidente: rojo=Critical, naranja=Major, amarillo=Minor,
    /// gris si aún no tiene severidad.
    static func color(for severity: IncidentSeverity?) -> Color {
        switch severity {
        case .critical: .red
        case .major: .orange
        case .minor: .yellow
        case .none: .gray
        }
    }

    /// Anotaciones de incidentes; descarta los que no tienen lat/lng. Preserva el
    /// orden de entrada.
    static func annotations(from incidents: [Incident]) -> [IncidentAnnotation] {
        incidents.compactMap { incident in
            guard let lat = incident.latitude, let lng = incident.longitude else {
                return nil
            }
            return IncidentAnnotation(
                id: incident.id,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                color: color(for: incident.severity),
                title: incident.incidentType?.label ?? "Incident",
                subtitle: incident.location ?? "",
                kind: .incident)
        }
    }

    /// Anotaciones de puestos de ayuda vial (siempre con coordenadas → azul).
    static func annotations(from posts: [TrafficAidPost]) -> [IncidentAnnotation] {
        posts.map { post in
            IncidentAnnotation(
                id: post.id,
                coordinate: CLLocationCoordinate2D(latitude: post.latitude, longitude: post.longitude),
                color: .blue,
                title: post.name,
                subtitle: post.address,
                kind: .trafficAid)
        }
    }
}
