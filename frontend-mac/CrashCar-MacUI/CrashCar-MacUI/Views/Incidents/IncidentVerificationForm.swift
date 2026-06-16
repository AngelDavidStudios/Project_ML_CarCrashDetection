//
//  IncidentVerificationForm.swift
//  CrashCar-MacUI
//
//  Sesión 7 — Formulario de verificación, espejo de `IncidentVerificationForm.tsx`.
//  El operador aprueba o rechaza; si aprueba, clasifica tipo/severidad e indica si
//  requiere respuesta. Las notas pasan a ser el motivo cuando se rechaza.
//

import SwiftUI

/// Decisión de verificación que emite el formulario al enviarse.
struct VerificationDecision: Sendable {
    let status: IncidentVerificationStatus   // `.approved` o `.rejected`
    let incidentType: IncidentIncidentType?
    let severity: IncidentSeverity?
    let notes: String
    let responseNeeded: Bool
}

struct IncidentVerificationForm: View {
    /// Acción de envío. Closure de UI (no async) — el contenedor la envuelve en
    /// un `Task` para llamar al ViewModel.
    let onSubmit: (VerificationDecision) -> Void
    var isSubmitting: Bool = false

    @State private var status: IncidentVerificationStatus = .approved
    @State private var incidentType: IncidentIncidentType?
    @State private var severity: IncidentSeverity?
    @State private var notes: String = ""
    @State private var responseNeeded: Bool = false

    private var isRejected: Bool { status == .rejected }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            decisionButtons

            if !isRejected {
                classification
            }

            notesField
            submitButton
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 20))
        .animation(.default, value: status)
    }

    // MARK: - Secciones

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Verification decision")
                .font(.headline)
            Text("Confirm or reject this detected incident.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var decisionButtons: some View {
        HStack(spacing: 12) {
            decisionButton(.approved, title: "Confirm", systemImage: "checkmark.circle.fill", tint: .green)
            decisionButton(.rejected, title: "Reject", systemImage: "xmark.circle.fill", tint: .red)
        }
    }

    private func decisionButton(_ value: IncidentVerificationStatus,
                                title: LocalizedStringKey,
                                systemImage: String,
                                tint: Color) -> some View {
        let selected = status == value
        return Button {
            status = value
        } label: {
            Label(title, systemImage: systemImage)
                .font(.body.weight(.medium))
                .foregroundStyle(selected ? tint : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selected ? tint.opacity(0.15) : .clear, in: .rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(selected ? tint : .secondary.opacity(0.3), lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }

    private var classification: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Incident type", selection: $incidentType) {
                Text("Select a type").tag(IncidentIncidentType?.none)
                ForEach(IncidentIncidentType.allCases, id: \.self) { type in
                    Text(LocalizedStringKey(type.label)).tag(IncidentIncidentType?.some(type))
                }
            }

            Picker("Severity", selection: $severity) {
                Text("Select severity").tag(IncidentSeverity?.none)
                ForEach(IncidentSeverity.allCases, id: \.self) { level in
                    Label(LocalizedStringKey(level.label), systemImage: level.systemImage)
                        .tag(IncidentSeverity?.some(level))
                }
            }

            Toggle(isOn: $responseNeeded) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Emergency response needed")
                    Text("Flag this incident for immediate dispatch.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(isRejected ? "Rejection reason" : "Additional notes"))
                .font(.subheadline.weight(.medium))
            TextEditor(text: $notes)
                .frame(minHeight: 80)
                .padding(6)
                .scrollContentBackground(.hidden)
                .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 8))
        }
    }

    private var submitButton: some View {
        Button {
            onSubmit(VerificationDecision(
                status: status,
                incidentType: isRejected ? nil : incidentType,
                severity: isRejected ? nil : severity,
                notes: notes,
                responseNeeded: isRejected ? false : responseNeeded))
        } label: {
            HStack {
                if isSubmitting { ProgressView().controlSize(.small) }
                Text(LocalizedStringKey(isRejected ? "Reject incident" : "Confirm incident"))
                    .frame(maxWidth: .infinity)
            }
        }
        .controlSize(.large)
        .buttonStyle(.borderedProminent)
        .tint(isRejected ? .red : .accentColor)
        .disabled(isSubmitting)
    }
}

nonisolated extension IncidentIncidentType: CaseIterable {
    public static var allCases: [IncidentIncidentType] {
        [.vehicleCollision, .fire, .pedestrianAccident, .debrisOnRoad,
         .stoppedVehicle, .wrongWayDriver, .other]
    }
}

nonisolated extension IncidentSeverity: CaseIterable {
    public static var allCases: [IncidentSeverity] {
        [.critical, .major, .minor]
    }
}

#Preview {
    IncidentVerificationForm(onSubmit: { _ in })
        .frame(width: 420)
        .padding()
}
