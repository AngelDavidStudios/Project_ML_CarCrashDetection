//
//  IncidentDetailView.swift
//  CrashCar-MacUI
//
//  Sesión 7 — Detalle de un incidente: imagen del accidente, datos y, según el
//  estado, el formulario de verificación (pendiente) o acciones de respuesta /
//  resolución (aprobado). Espejo de `incident_verification/[id]/page.tsx`.
//

import SwiftUI
import Amplify

struct IncidentDetailView: View {
    let incident: Incident
    let viewModel: IncidentViewModel
    /// Se invoca tras una acción con éxito para que el contenedor recargue la lista.
    let onFinished: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AccidentImageView(s3ImageKey: incident.s3ImageKey,
                                  fallbackImageUrl: incident.imageUrl)
                facts

                if let message = errorMessage {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(.red)
                }

                actionSection
            }
            .padding(24)
            .frame(maxWidth: 560)
        }
        .frame(minWidth: 520, minHeight: 600)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    // MARK: - Datos

    private var facts: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                VerificationStatusBadge(status: incident.verificationStatus)
                SeverityBadge(severity: incident.severity)
                if incident.responseInitiated {
                    Label("Response initiated", systemImage: "bolt.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.blue)
                }
            }

            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 16, verticalSpacing: 8) {
                factRow("Detected", incident.detectedAt.foundationDate
                    .formatted(date: .abbreviated, time: .standard))
                factRow("Confidence", incident.confidenceScore.asPercent)
                factRow("Type", incident.incidentType?.label ?? "—")
                factRow("Location", incident.location ?? "Unknown")
                if let lat = incident.latitude, let lng = incident.longitude {
                    factRow("Coordinates", String(format: "%.5f, %.5f", lat, lng))
                }
                if let notes = incident.notes, !notes.isEmpty {
                    factRow("Notes", notes)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(in: .rect(cornerRadius: 20))
    }

    private func factRow(_ label: LocalizedStringKey, _ value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
                .gridColumnAlignment(.leading)
            // El valor se trata como clave de catálogo: las claves conocidas
            // (tipo, "Unknown", "—") se traducen; los datos (ubicación, %, coords)
            // no están en el catálogo y se muestran tal cual.
            Text(LocalizedStringKey(value))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Acciones según estado

    @ViewBuilder
    private var actionSection: some View {
        switch incident.verificationStatus {
        case .pending, .none:
            IncidentVerificationForm(onSubmit: verify, isSubmitting: isSubmitting)
        case .approved:
            approvedActions
        case .rejected:
            ContentUnavailableView("Incident rejected",
                                   systemImage: "xmark.circle.fill",
                                   description: Text("This detection was marked as a false alarm."))
        }
    }

    private var approvedActions: some View {
        VStack(spacing: 12) {
            if !incident.responseInitiated {
                Button {
                    run { try await viewModel.initiateResponse(for: incident.id) }
                } label: {
                    Label("Initiate Response", systemImage: "bolt.fill")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
            }

            Button {
                run { _ = try await viewModel.resolveIncident(incident.id, notes: nil) }
            } label: {
                Label("Resolve", systemImage: "checkmark.seal.fill")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.bordered)
        }
        .disabled(isSubmitting)
    }

    // MARK: - Helpers

    private func verify(_ decision: VerificationDecision) {
        run {
            _ = try await viewModel.verifyIncident(
                incident.id,
                status: decision.status,
                type: decision.incidentType,
                severity: decision.severity,
                notes: decision.notes.isEmpty ? nil : decision.notes,
                responseNeeded: decision.responseNeeded)
        }
    }

    /// Ejecuta una acción async, gestionando estado de envío, error y cierre.
    private func run(_ action: @escaping () async throws -> Void) {
        isSubmitting = true
        errorMessage = nil
        Task {
            do {
                try await action()
                onFinished()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
        }
    }

}
