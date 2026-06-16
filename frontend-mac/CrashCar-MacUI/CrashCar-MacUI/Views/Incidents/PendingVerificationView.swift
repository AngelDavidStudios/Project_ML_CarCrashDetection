//
//  PendingVerificationView.swift
//  CrashCar-MacUI
//
//  Sesión 7 — Lista de incidentes pendientes de verificación, con filtro por
//  severidad y refresco en tiempo real (suscripción `onCreate`). Espejo de
//  `Pending_Verification/page.tsx`.
//
//  Nota: los incidentes recién detectados aún no tienen severidad (se asigna al
//  verificar), así que el filtro por severidad es efectivo sobre todo una vez
//  clasificados; por defecto se muestran todos.
//

import SwiftUI
import Amplify

struct PendingVerificationView: View {
    @StateObject private var viewModel = IncidentViewModel()

    @State private var severityFilter: IncidentSeverity?
    @State private var selected: Incident?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var pending: [Incident] {
        viewModel.incidents
            .filter { $0.verificationStatus == .pending }
            .filter { severityFilter == nil || $0.severity == severityFilter }
            .sorted { $0.detectedAt.foundationDate > $1.detectedAt.foundationDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            content
        }
        .padding(16)
        .navigationTitle("Pending Verification")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await load() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .task { await load() }
        .task { await observe() }
        .sheet(item: $selected) { incident in
            IncidentDetailView(incident: incident, viewModel: viewModel) {
                Task { await load() }
            }
        }
    }

    // MARK: - Header (título + filtro)

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Pending Verification")
                    .font(.largeTitle.bold())
                Text("Review and classify detected incidents.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Picker("Severity", selection: $severityFilter) {
                Text("All severities").tag(IncidentSeverity?.none)
                ForEach(IncidentSeverity.allCases, id: \.self) { level in
                    Text(LocalizedStringKey(level.label)).tag(IncidentSeverity?.some(level))
                }
            }
            .pickerStyle(.menu)
            .fixedSize()
        }
    }

    // MARK: - Contenido

    @ViewBuilder
    private var content: some View {
        if isLoading && pending.isEmpty {
            ProgressView("Loading incidents…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if pending.isEmpty {
            ContentUnavailableView("All clear",
                                   systemImage: "checkmark.circle",
                                   description: Text("No incidents are awaiting verification."))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            incidentsTable
        }
    }

    private var incidentsTable: some View {
        Table(pending) {
            TableColumn("Detected") { incident in
                Text(incident.detectedAt.foundationDate
                    .formatted(date: .abbreviated, time: .shortened))
            }
            TableColumn("Location") { incident in
                (incident.location.map { Text(verbatim: $0) } ?? Text("Unknown"))
                    .foregroundStyle(incident.location == nil ? .secondary : .primary)
            }
            TableColumn("Confidence") { incident in
                Text(incident.confidenceScore.asPercent)
                    .monospacedDigit()
            }
            TableColumn("Severity") { incident in
                SeverityBadge(severity: incident.severity)
            }
            TableColumn("") { incident in
                Button("Review") { selected = incident }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            .width(80)
        }
        .glassEffect(in: .rect(cornerRadius: 16))
    }

    // MARK: - Carga y realtime

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            try await viewModel.fetchIncidents(status: .pending)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Refresca la lista cuando el backend crea un incidente nuevo (suscripción).
    private func observe() async {
        for await _ in viewModel.observeNewIncidents() {
            await load()
        }
    }
}
