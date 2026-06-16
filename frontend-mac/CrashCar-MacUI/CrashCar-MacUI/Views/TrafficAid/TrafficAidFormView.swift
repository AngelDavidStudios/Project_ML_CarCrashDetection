//
//  TrafficAidFormView.swift
//  CrashCar-MacUI
//
//  Sesión 9 — Formulario de creación/edición de un puesto de ayuda vial, con
//  validación de campos requeridos. Espejo de los diálogos Add/Edit del Next.js.
//

import SwiftUI

extension TrafficAidFormData {
    static let empty = TrafficAidFormData(
        name: "", address: "", latitude: 0, longitude: 0, contactNumber: "")

    /// Reconstruye los datos del formulario desde un puesto existente (para editar).
    init(post: TrafficAidPost) {
        self.init(
            name: post.name,
            address: post.address,
            latitude: post.latitude,
            longitude: post.longitude,
            contactNumber: post.contactNumber,
            hasPoliceService: post.hasPoliceService,
            hasAmbulance: post.hasAmbulance,
            hasFireService: post.hasFireService,
            operatingHours: post.operatingHours,
            additionalInfo: post.additionalInfo ?? "",
            status: post.status)
    }
}

struct TrafficAidFormView: View {
    enum Mode: Equatable {
        case create
        case edit

        var title: String { self == .create ? "New Traffic Aid Post" : "Edit Traffic Aid Post" }
        var actionLabel: String { self == .create ? "Create" : "Save changes" }
    }

    static let statuses = ["active", "inactive", "maintenance"]

    let mode: Mode
    var isSubmitting: Bool
    /// Acción de UI (no async); el contenedor la envuelve en un `Task`.
    let onSave: (TrafficAidFormData) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var data: TrafficAidFormData
    @State private var missing: [String] = []

    init(mode: Mode,
         initial: TrafficAidFormData = .empty,
         isSubmitting: Bool = false,
         onSave: @escaping (TrafficAidFormData) -> Void) {
        self.mode = mode
        self.isSubmitting = isSubmitting
        self.onSave = onSave
        _data = State(initialValue: initial)
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Identification") {
                    TextField("Name", text: $data.name)
                        .textFieldStyle(.roundedBorder)
                    TextField("Address", text: $data.address)
                        .textFieldStyle(.roundedBorder)
                    TextField("Contact number", text: $data.contactNumber)
                        .textFieldStyle(.roundedBorder)
                }

                Section("Location") {
                    TextField("Latitude", value: $data.latitude, format: .number)
                        .textFieldStyle(.roundedBorder)
                    TextField("Longitude", value: $data.longitude, format: .number)
                        .textFieldStyle(.roundedBorder)
                }

                Section("Services") {
                    Toggle("Police", isOn: $data.hasPoliceService)
                    Toggle("Ambulance", isOn: $data.hasAmbulance)
                    Toggle("Fire service", isOn: $data.hasFireService)
                }

                Section("Operations") {
                    TextField("Operating hours", text: $data.operatingHours)
                        .textFieldStyle(.roundedBorder)
                    Picker("Status", selection: $data.status) {
                        ForEach(Self.statuses, id: \.self) { status in
                            Text(LocalizedStringKey(status.capitalized)).tag(status)
                        }
                    }
                    TextField("Additional info", text: $data.additionalInfo, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                }

                if !missing.isEmpty {
                    Label("Required: \(missing.joined(separator: ", "))",
                          systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.callout)
                }
            }
            .formStyle(.grouped)

            footer
        }
        .frame(width: 460, height: 600)
        .navigationTitle(LocalizedStringKey(mode.title))
    }

    private var footer: some View {
        HStack {
            Button("Cancel") { dismiss() }
            Spacer()
            Button {
                let missingFields = data.missingRequiredFields()
                missing = missingFields
                if missingFields.isEmpty { onSave(data) }
            } label: {
                HStack {
                    if isSubmitting { ProgressView().controlSize(.small) }
                    Text(LocalizedStringKey(mode.actionLabel))
                }
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .disabled(isSubmitting)
        }
        .padding(16)
    }
}

#Preview {
    TrafficAidFormView(mode: .create) { _ in }
}
