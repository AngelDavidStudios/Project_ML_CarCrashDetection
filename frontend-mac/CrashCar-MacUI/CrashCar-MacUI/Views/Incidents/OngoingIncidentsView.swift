//
//  OngoingIncidentsView.swift
//  CrashCar-MacUI
//
//  Sesión 8 — Incidentes activos (aprobados, no resueltos) con vista de lista o
//  de mapa, filtros por severidad y tipo. Espejo de `Ongoing_Incidents/page.tsx`.
//
//  Nota: el plan mencionaba paginación cursor-based con DataStore; este proyecto
//  usa `AWSAPIPlugin`, así que se cargan los aprobados y se filtran/ordenan en
//  cliente (suficiente para el volumen esperado).
//

import SwiftUI
import Amplify

struct OngoingIncidentsView: View {
    @StateObject private var viewModel = IncidentViewModel()
    @StateObject private var trafficViewModel = TrafficAidViewModel()

    @State private var mode: Mode = .list
    @State private var severityFilter: IncidentSeverity?
    @State private var typeFilter: IncidentIncidentType?
    @State private var selected: Incident?
    @State private var isLoading = false
    @State private var errorMessage: String?

    enum Mode: String, CaseIterable, Identifiable {
        case list, map
        var id: String { rawValue }
        var label: String { self == .list ? "List" : "Map" }
        var systemImage: String { self == .list ? "list.bullet" : "map" }
    }

    private var ongoing: [Incident] {
        viewModel.incidents
            .filter { $0.verificationStatus == .approved && $0.resolvedAt == nil }
            .filter { severityFilter == nil || $0.severity == severityFilter }
            .filter { typeFilter == nil || $0.incidentType == typeFilter }
            .sorted { $0.detectedAt.foundationDate > $1.detectedAt.foundationDate }
    }

    private var annotations: [IncidentAnnotation] {
        MapAnnotationBuilder.annotations(from: ongoing)
            + MapAnnotationBuilder.annotations(from: trafficViewModel.posts)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            filters

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            content
        }
        .padding(16)
        .navigationTitle("Ongoing Incidents")
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
        .sheet(item: $selected) { incident in
            IncidentDetailView(incident: incident, viewModel: viewModel) {
                Task { await load() }
            }
        }
    }

    // MARK: - Header + filtros

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Ongoing Incidents")
                    .font(.largeTitle.bold())
                Text("Verified incidents awaiting response or resolution.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Picker("View", selection: $mode) {
                ForEach(Mode.allCases) { mode in
                    Label(LocalizedStringKey(mode.label), systemImage: mode.systemImage).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .fixedSize()
        }
    }

    private var filters: some View {
        HStack(spacing: 12) {
            Picker("Severity", selection: $severityFilter) {
                Text("All severities").tag(IncidentSeverity?.none)
                ForEach(IncidentSeverity.allCases, id: \.self) { level in
                    Text(LocalizedStringKey(level.label)).tag(IncidentSeverity?.some(level))
                }
            }
            .fixedSize()

            Picker("Type", selection: $typeFilter) {
                Text("All types").tag(IncidentIncidentType?.none)
                ForEach(IncidentIncidentType.allCases, id: \.self) { type in
                    Text(LocalizedStringKey(type.label)).tag(IncidentIncidentType?.some(type))
                }
            }
            .fixedSize()

            Spacer()
            Text("\(ongoing.count) active")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Contenido

    @ViewBuilder
    private var content: some View {
        if isLoading && ongoing.isEmpty {
            ProgressView("Loading incidents…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if mode == .map {
            IncidentMapView(annotations: annotations)
                .clipShape(.rect(cornerRadius: 16))
        } else if ongoing.isEmpty {
            ContentUnavailableView("No active incidents",
                                   systemImage: "checkmark.circle",
                                   description: Text("Verified incidents will appear here until resolved."))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            incidentsTable
        }
    }

    private var incidentsTable: some View {
        Table(ongoing) {
            TableColumn("Detected") { incident in
                Text(incident.detectedAt.foundationDate
                    .formatted(date: .abbreviated, time: .shortened))
            }
            TableColumn("Type") { incident in
                incident.incidentType.map { Text(LocalizedStringKey($0.label)) } ?? Text(verbatim: "—")
            }
            TableColumn("Severity") { incident in
                SeverityBadge(severity: incident.severity)
            }
            TableColumn("Location") { incident in
                (incident.location.map { Text(verbatim: $0) } ?? Text("Unknown"))
                    .foregroundStyle(incident.location == nil ? .secondary : .primary)
            }
            TableColumn("") { incident in
                HStack(spacing: 6) {
                    if incident.responseInitiated {
                        Image(systemName: "bolt.fill").foregroundStyle(.blue)
                    }
                    Button("Manage") { selected = incident }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            }
            .width(110)
        }
        .glassEffect(in: .rect(cornerRadius: 16))
    }

    // MARK: - Carga

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            try await viewModel.fetchIncidents(status: .approved)
        } catch {
            errorMessage = error.localizedDescription
        }
        // Los puestos de ayuda son opcionales para el mapa; un fallo no bloquea.
        do {
            try await trafficViewModel.fetchPosts()
        } catch {
            Amplify.Logging.error("fetchPosts (mapa) falló: \(error)")
        }
        isLoading = false
    }
}
