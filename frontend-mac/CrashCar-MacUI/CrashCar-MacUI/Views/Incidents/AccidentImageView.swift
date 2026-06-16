//
//  AccidentImageView.swift
//  CrashCar-MacUI
//
//  Sesión 10 — Muestra la imagen de un accidente, prefiriendo S3.
//
//  Resuelve primero la `s3ImageKey` vía Amplify Storage (URL firmada); si no hay
//  key o la resolución falla, cae al `imageUrl` estático que sirve el backend
//  FastAPI (compatibilidad con incidentes creados antes de la migración a S3).
//

import SwiftUI
import Amplify

struct AccidentImageView: View {
    /// Key del objeto en S3 (`accidents/<file>`), si la imagen ya está migrada.
    let s3ImageKey: String?
    /// Ruta estática del backend (`/accident_images/<file>`) como respaldo.
    let fallbackImageUrl: String?

    var cornerRadius: CGFloat = 12
    var minHeight: CGFloat = 240

    @State private var resolvedURL: URL?
    @State private var didResolve = false

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .task(id: s3ImageKey) { await resolve() }
    }

    @ViewBuilder
    private var content: some View {
        if let url = resolvedURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fit)
                case .failure:
                    placeholder("Image unavailable", systemImage: "photo.badge.exclamationmark")
                case .empty:
                    ProgressView().frame(maxWidth: .infinity, minHeight: minHeight)
                @unknown default:
                    placeholder("Image unavailable", systemImage: "photo")
                }
            }
            .background(.black.opacity(0.25), in: .rect(cornerRadius: cornerRadius))
        } else if !didResolve {
            ProgressView().frame(maxWidth: .infinity, minHeight: minHeight)
        } else {
            placeholder("No image", systemImage: "photo")
        }
    }

    private func placeholder(_ text: LocalizedStringKey, systemImage: String) -> some View {
        ContentUnavailableView(text, systemImage: systemImage)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .background(.quaternary.opacity(0.3), in: .rect(cornerRadius: cornerRadius))
    }

    /// Resuelve la URL a mostrar: S3 primero, backend estático como respaldo.
    private func resolve() async {
        didResolve = false
        resolvedURL = nil

        if let key = s3ImageKey, !key.isEmpty {
            do {
                resolvedURL = try await Amplify.Storage.getURL(path: .fromString(key))
                didResolve = true
                return
            } catch {
                Amplify.Logging.error("No se pudo resolver la URL S3 \(key): \(error)")
            }
        }

        if let path = fallbackImageUrl, !path.isEmpty {
            resolvedURL = URL(string: path, relativeTo: AppSettings.shared.backendHTTPBaseURL)
        }
        didResolve = true
    }
}
