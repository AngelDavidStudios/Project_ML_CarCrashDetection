//
//  DetectionView.swift
//  CrashCar-MacUI
//
//  Sesión 6 — Vista de detección: el operador sube un vídeo, FastAPI lo procesa
//  y los frames anotados se muestran en tiempo real, con un log de eventos.
//
//  Diseño LiquidGlass: paneles con `.glassEffect()`, sin fondos opacos manuales.
//

import SwiftUI

struct DetectionView: View {
    @StateObject private var viewModel = DetectionViewModel()

    @State private var cameraName = ""
    @State private var latitude = ""
    @State private var longitude = ""

    var body: some View {
        HSplitView {
            videoPanel
                .frame(minWidth: 420, idealWidth: 640)
            logPanel
                .frame(minWidth: 280, idealWidth: 340)
        }
        .padding(16)
        .navigationTitle("Detection")
    }

    // MARK: - Panel izquierdo (vídeo + controles)

    private var videoPanel: some View {
        VStack(spacing: 16) {
            videoPreview
            metadataInputs
            controls
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .glassEffect(in: .rect(cornerRadius: 20))
    }

    private var videoPreview: some View {
        ZStack {
            if let frame = viewModel.currentFrame {
                Image(decorative: frame, scale: 1.0)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ContentUnavailableView(
                    LocalizedStringKey(viewModel.selectedVideoURL == nil ? "No video selected" : "Ready to detect"),
                    systemImage: "video.badge.waveform",
                    description: viewModel.selectedVideoURL.map { Text(verbatim: $0.lastPathComponent) }
                        ?? Text("Upload a video to begin"))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .background(.black.opacity(0.25), in: .rect(cornerRadius: 12))
        .overlay(alignment: .bottom) {
            if viewModel.progress > 0 && viewModel.progress < 1 {
                ProgressView(value: viewModel.progress)
                    .padding(8)
            }
        }
    }

    private var metadataInputs: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
            GridRow {
                Text("Location").foregroundStyle(.secondary)
                TextField("Camera name", text: $cameraName)
                    .textFieldStyle(.roundedBorder)
                    .gridCellColumns(3)
            }
            GridRow {
                Text("Latitude").foregroundStyle(.secondary)
                TextField("-2.17", text: $latitude)
                    .textFieldStyle(.roundedBorder)
                Text("Longitude").foregroundStyle(.secondary)
                TextField("-79.92", text: $longitude)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .disabled(viewModel.isBusy)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.pickVideo()
            } label: {
                Label("Upload Video", systemImage: "square.and.arrow.up")
            }
            .disabled(viewModel.isBusy)

            Button {
                viewModel.startDetection(
                    cameraName: cameraName,
                    latitude: Double(latitude),
                    longitude: Double(longitude))
            } label: {
                Label("Start Detection", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedVideoURL == nil || viewModel.isBusy)

            Spacer()

            Button(role: .destructive) {
                viewModel.removeVideo()
            } label: {
                Label("Remove", systemImage: "trash")
            }
            .disabled(viewModel.selectedVideoURL == nil)
        }
    }

    // MARK: - Panel derecho (log)

    private var logPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Detection Log")
                .font(.headline)
                .padding(.bottom, 8)

            if viewModel.logs.isEmpty {
                ContentUnavailableView("No events yet",
                                       systemImage: "list.bullet.rectangle")
                    .frame(maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            ForEach(viewModel.logs) { log in
                                DetectionLogRow(log: log).id(log.id)
                            }
                        }
                    }
                    .onChange(of: viewModel.logs.count) {
                        if let last = viewModel.logs.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .glassEffect(in: .rect(cornerRadius: 20))
    }
}

// MARK: - Fila de log

private struct DetectionLogRow: View {
    let log: DetectionLog

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
            Text(log.message)
                .font(.callout)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(log.timestamp, format: .dateTime.hour().minute().second())
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(color.opacity(0.08), in: .rect(cornerRadius: 8))
    }

    private var color: Color {
        switch log.severity {
        case .info: .secondary
        case .success: .green
        case .warning: .orange
        case .error: .red
        }
    }

    private var icon: String {
        switch log.severity {
        case .info: "info.circle"
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.octagon.fill"
        }
    }
}

#Preview {
    DetectionView()
        .frame(width: 1000, height: 640)
}
