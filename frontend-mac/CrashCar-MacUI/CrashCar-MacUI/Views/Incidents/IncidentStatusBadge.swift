//
//  IncidentStatusBadge.swift
//  CrashCar-MacUI
//
//  Sesión 7 — Badges de estado de verificación y de severidad, espejo de
//  `IncidentStatusBadge.tsx` del frontend Next.js. Colores e iconos por caso.
//

import SwiftUI

// MARK: - Helpers de presentación de los enums

extension IncidentVerificationStatus {
    var label: String {
        switch self {
        case .pending: "Pending"
        case .approved: "Verified"
        case .rejected: "Rejected"
        }
    }

    var color: Color {
        switch self {
        case .pending: .orange
        case .approved: .green
        case .rejected: .red
        }
    }

    var systemImage: String {
        switch self {
        case .pending: "clock"
        case .approved: "checkmark.circle.fill"
        case .rejected: "xmark.circle.fill"
        }
    }
}

extension IncidentSeverity {
    var label: String {
        switch self {
        case .critical: "Critical"
        case .major: "Major"
        case .minor: "Minor"
        }
    }

    var color: Color {
        switch self {
        case .critical: .red
        case .major: .orange
        case .minor: .blue
        }
    }

    var systemImage: String {
        switch self {
        case .critical: "exclamationmark.triangle.fill"
        case .major: "exclamationmark.circle.fill"
        case .minor: "info.circle.fill"
        }
    }
}

extension IncidentIncidentType {
    var label: String {
        switch self {
        case .vehicleCollision: "Vehicle Collision"
        case .fire: "Fire"
        case .pedestrianAccident: "Pedestrian Accident"
        case .debrisOnRoad: "Debris on Road"
        case .stoppedVehicle: "Stopped Vehicle"
        case .wrongWayDriver: "Wrong-Way Driver"
        case .other: "Other"
        }
    }
}

// MARK: - Badge genérico

/// Cápsula de color tenue con icono + texto, sobre material translúcido.
private struct PillBadge: View {
    let text: LocalizedStringKey
    let systemImage: String
    let color: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .labelStyle(.titleAndIcon)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: .capsule)
    }
}

// MARK: - Badges públicos

struct VerificationStatusBadge: View {
    let status: IncidentVerificationStatus?

    var body: some View {
        if let status {
            PillBadge(text: LocalizedStringKey(status.label), systemImage: status.systemImage, color: status.color)
        } else {
            PillBadge(text: "Unknown", systemImage: "questionmark.circle", color: .secondary)
        }
    }
}

struct SeverityBadge: View {
    let severity: IncidentSeverity?

    var body: some View {
        if let severity {
            PillBadge(text: LocalizedStringKey(severity.label), systemImage: severity.systemImage, color: severity.color)
        } else {
            PillBadge(text: "—", systemImage: "minus", color: .secondary)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        VerificationStatusBadge(status: .pending)
        VerificationStatusBadge(status: .approved)
        VerificationStatusBadge(status: .rejected)
        SeverityBadge(severity: .critical)
        SeverityBadge(severity: .major)
        SeverityBadge(severity: .minor)
    }
    .padding()
}
