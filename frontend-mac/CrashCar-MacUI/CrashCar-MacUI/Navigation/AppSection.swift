//
//  AppSection.swift
//  CrashCar-MacUI
//
//  Sesión 4 — Secciones navegables del shell. Espejo del `app-sidebar.tsx`
//  del frontend Next.js: Detection, Pending Verification, Ongoing Incidents,
//  Traffic Aid. (Settings no es una sección: vive en el footer del sidebar.)
//

import Foundation

/// Una sección principal de la app, seleccionable en el sidebar.
///
/// `Identifiable` + `Hashable` para usarse como `selection` en `List` /
/// `NavigationSplitView`. `CaseIterable` para poblar el sidebar y los tests.
enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case detection
    case pendingVerification
    case ongoingIncidents
    case trafficAid

    var id: String { rawValue }

    /// Grupo del sidebar al que pertenece (espejo de los `NavMain` del Next.js).
    enum Group: String, CaseIterable, Identifiable {
        case detection
        case incident
        case traffic

        var id: String { rawValue }

        /// Título del grupo. La localización EN/ES real llega en la Sesión 11.
        var title: String {
            switch self {
            case .detection: "Detection"
            case .incident:  "Incidents"
            case .traffic:   "Traffic"
            }
        }
    }

    var group: Group {
        switch self {
        case .detection:          .detection
        case .pendingVerification, .ongoingIncidents: .incident
        case .trafficAid:         .traffic
        }
    }

    /// Título visible de la sección. La localización EN/ES real llega en la Sesión 11.
    var title: String {
        switch self {
        case .detection:          "Accident Detection"
        case .pendingVerification: "Pending Verification"
        case .ongoingIncidents:   "Ongoing Incidents"
        case .trafficAid:         "Traffic Aid"
        }
    }

    /// SF Symbol del item, según el plan de migración (Sesión 4, paso 2).
    var systemImage: String {
        switch self {
        case .detection:          "video.badge.waveform"
        case .pendingVerification: "clock.badge.exclamationmark"
        case .ongoingIncidents:   "exclamationmark.triangle"
        case .trafficAid:         "cross.case"
        }
    }
}
