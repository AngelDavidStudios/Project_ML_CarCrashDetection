//
//  TrafficAidView.swift
//  CrashCar-MacUI
//
//  Sesión 9 — CRUD de puestos de ayuda vial: tabla con filtro por estado, crear,
//  editar y eliminar (con confirmación). Espejo de `Traffic_Aid` del Next.js.
//

import SwiftUI

struct TrafficAidView: View {
    @StateObject private var viewModel = TrafficAidViewModel()

    @State private var statusFilter: String?
    @State private var isLoading = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    @State private var showingCreate = false
    @State private var editing: TrafficAidPost?
    @State private var pendingDelete: TrafficAidPost?

    private var filtered: [TrafficAidPost] {
        viewModel.posts
            .filter { statusFilter == nil || $0.status == statusFilter }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
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
        .navigationTitle("Traffic Aid")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreate = true
                } label: {
                    Label("Add Post", systemImage: "plus")
                }
            }
        }
        .task { await load() }
        .sheet(isPresented: $showingCreate) {
            TrafficAidFormView(mode: .create, isSubmitting: isSubmitting) { data in
                submit(dismiss: { showingCreate = false }) {
                    try await viewModel.createPost(data)
                }
            }
        }
        .sheet(item: $editing) { post in
            TrafficAidFormView(mode: .edit,
                               initial: TrafficAidFormData(post: post),
                               isSubmitting: isSubmitting) { data in
                submit(dismiss: { editing = nil }) {
                    try await viewModel.updatePost(post.id, changes: data.asChanges)
                }
            }
        }
        .confirmationDialog("Delete this post?",
                            isPresented: deleteDialogBinding,
                            presenting: pendingDelete) { post in
            Button("Delete \(post.name)", role: .destructive) {
                submit(dismiss: { pendingDelete = nil }) {
                    try await viewModel.deletePost(post.id)
                }
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        }
    }

    // MARK: - Header + filtro

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Traffic Aid Posts")
                    .font(.largeTitle.bold())
                Text("Emergency response points shown on the incident map.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Picker("Status", selection: $statusFilter) {
                Text("All statuses").tag(String?.none)
                ForEach(TrafficAidFormView.statuses, id: \.self) { status in
                    Text(LocalizedStringKey(status.capitalized)).tag(String?.some(status))
                }
            }
            .fixedSize()
        }
    }

    // MARK: - Contenido

    @ViewBuilder
    private var content: some View {
        if isLoading && filtered.isEmpty {
            ProgressView("Loading posts…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if filtered.isEmpty {
            ContentUnavailableView("No traffic aid posts",
                                   systemImage: "cross.case",
                                   description: Text("Add a post to show it on the incident map."))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            postsTable
        }
    }

    private var postsTable: some View {
        Table(filtered) {
            TableColumn("Name") { post in
                Text(post.name).fontWeight(.medium)
            }
            TableColumn("Address") { post in
                Text(post.address).foregroundStyle(.secondary)
            }
            TableColumn("Services") { post in
                servicesCell(post)
            }
            TableColumn("Status") { post in
                StatusPill(status: post.status)
            }
            TableColumn("") { post in
                HStack(spacing: 6) {
                    Button("Edit") { editing = post }
                        .controlSize(.small)
                    Button(role: .destructive) { pendingDelete = post } label: {
                        Image(systemName: "trash")
                    }
                    .controlSize(.small)
                }
            }
            .width(120)
        }
        .glassEffect(in: .rect(cornerRadius: 16))
    }

    private func servicesCell(_ post: TrafficAidPost) -> some View {
        HStack(spacing: 8) {
            serviceIcon("shield.lefthalf.filled", available: post.hasPoliceService, help: "Police")
            serviceIcon("cross.case.fill", available: post.hasAmbulance, help: "Ambulance")
            serviceIcon("flame.fill", available: post.hasFireService, help: "Fire service")
        }
    }

    private func serviceIcon(_ systemImage: String, available: Bool, help: LocalizedStringKey) -> some View {
        Image(systemName: systemImage)
            .foregroundStyle(available ? .blue : .secondary.opacity(0.3))
            .help(help)
    }

    // MARK: - Acciones

    private var deleteDialogBinding: Binding<Bool> {
        Binding(get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } })
    }

    private func submit(dismiss: @escaping () -> Void,
                        _ work: @escaping () async throws -> Void) {
        isSubmitting = true
        errorMessage = nil
        Task {
            do {
                try await work()
                dismiss()
                await load()
            } catch {
                errorMessage = Self.friendly(error)
            }
            isSubmitting = false
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            try await viewModel.fetchPosts()
        } catch {
            errorMessage = Self.friendly(error)
        }
        isLoading = false
    }

    private static func friendly(_ error: Error) -> String {
        if case let TrafficAidError.missingRequiredFields(fields) = error {
            return "Missing required fields: \(fields.joined(separator: ", "))"
        }
        return error.localizedDescription
    }
}

// MARK: - Status pill

private struct StatusPill: View {
    let status: String

    var body: some View {
        Text(LocalizedStringKey(status.capitalized))
            .font(.caption.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: .capsule)
    }

    private var color: Color {
        switch status {
        case "active": .green
        case "maintenance": .orange
        default: .secondary
        }
    }
}

private extension TrafficAidFormData {
    /// Convierte el formulario completo en un set de cambios (para editar).
    var asChanges: TrafficAidChanges {
        TrafficAidChanges(
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude,
            contactNumber: contactNumber,
            hasPoliceService: hasPoliceService,
            hasAmbulance: hasAmbulance,
            hasFireService: hasFireService,
            operatingHours: operatingHours,
            additionalInfo: additionalInfo.isEmpty ? nil : additionalInfo,
            status: status)
    }
}
