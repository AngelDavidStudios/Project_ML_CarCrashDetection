//
//  ImageUploadService.swift
//  CrashCar-MacUI
//
//  Sesión 10 — Sube a S3 las imágenes de accidentes que sirve FastAPI.
//
//  El backend FastAPI guarda la imagen recortada del accidente y la expone como
//  estática (`/accident_images/<file>`). Este servicio la descarga desde el
//  backend y la re-sube a S3 (Amplify Storage Gen 2) bajo `accidents/`, para que
//  la app la sirva desde S3 en vez de depender del host del backend.
//
//  Concurrencia (Approachable Concurrency): tipos `nonisolated` + `Sendable` para
//  poder ejecutarse fuera del MainActor. Toda la E/S es `async throws` — sin
//  DispatchQueue ni completion handlers. Las dependencias (descarga HTTP y
//  almacenamiento S3) se inyectan como protocolos para testear sin red ni AWS.
//

import Foundation
import Amplify

// MARK: - Errores

nonisolated enum ImageUploadError: Error, Equatable {
    /// La URL local del backend no pudo resolverse contra la base HTTP.
    case invalidURL(String)
    /// La descarga desde el backend devolvió un estado HTTP no exitoso.
    case downloadFailed(status: Int)
}

// MARK: - Abstracciones inyectables

/// Descarga los bytes de una imagen desde una URL HTTP. Inyectable para testear
/// sin red (la impl real usa `URLSession`).
nonisolated protocol ImageDataFetching: Sendable {
    func data(from url: URL) async throws -> Data
}

/// Descarga vía `URLSession`, validando el código de estado HTTP.
nonisolated struct URLSessionImageFetcher: ImageDataFetching {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ImageUploadError.downloadFailed(status: http.statusCode)
        }
        return data
    }
}

/// Almacenamiento de imágenes de accidentes en S3. Inyectable para testear sin
/// AWS (la impl real es `AmplifyImageStorage`).
nonisolated protocol AccidentImageStorage: Sendable {
    /// Sube `data` bajo `path` y devuelve la key resuelta.
    func upload(data: Data, toPath path: String) async throws -> String
    /// Devuelve una URL (firmada) para leer el objeto en `path`.
    func url(forPath path: String) async throws -> URL
}

/// Implementación real sobre Amplify Storage Gen 2 (`AWSS3StoragePlugin`).
nonisolated struct AmplifyImageStorage: AccidentImageStorage {
    func upload(data: Data, toPath path: String) async throws -> String {
        let task = Amplify.Storage.uploadData(path: .fromString(path), data: data)
        return try await task.value
    }

    func url(forPath path: String) async throws -> URL {
        try await Amplify.Storage.getURL(path: .fromString(path))
    }
}

// MARK: - Servicio

/// Capacidad de subir la imagen de un accidente a S3. La consume el
/// `DetectionViewModel`; abstraída para poder inyectar un mock en sus tests.
nonisolated protocol AccidentImageUploading: Sendable {
    /// Descarga la imagen que sirve FastAPI en `localFastAPIUrl` y la sube a S3.
    /// Devuelve la key S3 resultante.
    func uploadAccidentImage(from localFastAPIUrl: String) async throws -> String
}

nonisolated struct ImageUploadService: AccidentImageUploading {

    private let fetcher: ImageDataFetching
    private let storage: AccidentImageStorage
    private let httpBaseURL: URL

    init(fetcher: ImageDataFetching = URLSessionImageFetcher(),
         storage: AccidentImageStorage = AmplifyImageStorage(),
         httpBaseURL: URL) {
        self.fetcher = fetcher
        self.storage = storage
        self.httpBaseURL = httpBaseURL
    }

    /// Convierte la ruta estática del backend (`/accident_images/<file>`) en la
    /// key S3 bajo el prefijo `accidents/` (que coincide con la regla de acceso
    /// `'accidents/*'` de `amplify/storage/resource.ts`).
    static func s3Key(for localFastAPIUrl: String) -> String {
        let filename = (localFastAPIUrl as NSString).lastPathComponent
        return "accidents/\(filename)"
    }

    func uploadAccidentImage(from localFastAPIUrl: String) async throws -> String {
        guard let downloadURL = URL(string: localFastAPIUrl, relativeTo: httpBaseURL)?.absoluteURL else {
            throw ImageUploadError.invalidURL(localFastAPIUrl)
        }
        let data = try await fetcher.data(from: downloadURL)
        return try await storage.upload(data: data, toPath: Self.s3Key(for: localFastAPIUrl))
    }

    /// URL (firmada) para mostrar una imagen ya almacenada en S3.
    func getImageURL(for s3Key: String) async throws -> URL {
        try await storage.url(forPath: s3Key)
    }
}
