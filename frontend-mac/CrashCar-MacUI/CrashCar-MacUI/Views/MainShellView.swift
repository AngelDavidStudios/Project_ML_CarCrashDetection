//
//  MainShellView.swift
//  CrashCar-MacUI
//
//  Sesión 4 — Shell de la app autenticada: NavigationSplitView (sidebar + detalle)
//  con diseño LiquidGlass. Desde la Sesión 9 las 4 secciones tienen su vista real
//  (Detection→S6, Pending→S7, Ongoing→S8, Traffic Aid→S9).
//

import SwiftUI

struct MainShellView: View {
    @State private var selection: AppSection? = .detection

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 240, ideal: 260, max: 320)
        } detail: {
            detail
        }
        // Tap en una notificación de accidente → abrir la sección de incidentes.
        .onReceive(NotificationCenter.default.publisher(for: .openIncidentRequested)) { _ in
            selection = .pendingVerification
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let selection {
            sectionView(for: selection)
                .id(selection)
        } else {
            ContentUnavailableView("Select a section",
                                   systemImage: "sidebar.left")
        }
    }

    @ViewBuilder
    private func sectionView(for section: AppSection) -> some View {
        switch section {
        case .detection:
            DetectionView()
        case .pendingVerification:
            PendingVerificationView()
        case .ongoingIncidents:
            OngoingIncidentsView()
        case .trafficAid:
            TrafficAidView()
        }
    }
}

#Preview {
    MainShellView()
        .environmentObject(AuthViewModel())
        .environmentObject(AppSettings())
        .frame(width: 900, height: 600)
}
