//
//  IncidentMapView.swift
//  CrashCar-MacUI
//
//  Sesión 8 — Mapa MapKit con pins de incidentes (color por severidad) y puestos
//  de ayuda vial (azul). Tocar un pin abre un resumen en una hoja.
//

import SwiftUI
import MapKit

struct IncidentMapView: View {
    let annotations: [IncidentAnnotation]

    @State private var camera: MapCameraPosition = .automatic
    @State private var selected: IncidentAnnotation?

    var body: some View {
        Map(position: $camera) {
            ForEach(annotations) { annotation in
                Annotation(annotation.title, coordinate: annotation.coordinate) {
                    Button {
                        selected = annotation
                    } label: {
                        pin(for: annotation)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .overlay(alignment: .topTrailing) { legend }
        .sheet(item: $selected) { summarySheet($0) }
    }

    // MARK: - Pin

    private func pin(for annotation: IncidentAnnotation) -> some View {
        Image(systemName: annotation.kind == .trafficAid ? "cross.case.fill" : "exclamationmark.triangle.fill")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .padding(7)
            .background(annotation.color, in: .circle)
            .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
            .shadow(radius: 2)
    }

    // MARK: - Leyenda

    private var legend: some View {
        VStack(alignment: .leading, spacing: 6) {
            legendRow(.red, "Critical")
            legendRow(.orange, "Major")
            legendRow(.yellow, "Minor")
            legendRow(.blue, "Traffic aid")
        }
        .font(.caption)
        .padding(10)
        .glassEffect(in: .rect(cornerRadius: 12))
        .padding(12)
    }

    private func legendRow(_ color: Color, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(text).foregroundStyle(.secondary)
        }
    }

    // MARK: - Resumen

    private func summarySheet(_ annotation: IncidentAnnotation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(LocalizedStringKey(annotation.kind == .trafficAid ? "Traffic Aid Post" : "Incident"),
                  systemImage: annotation.kind == .trafficAid ? "cross.case.fill" : "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(annotation.color)

            Text(verbatim: annotation.title)
                .font(.title3.bold())
            if !annotation.subtitle.isEmpty {
                Text(annotation.subtitle)
                    .foregroundStyle(.secondary)
            }
            Text(String(format: "%.5f, %.5f",
                        annotation.coordinate.latitude, annotation.coordinate.longitude))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            Button("Close") { selected = nil }
                .frame(maxWidth: .infinity)
                .controlSize(.large)
        }
        .padding(24)
        .frame(minWidth: 320)
    }
}
