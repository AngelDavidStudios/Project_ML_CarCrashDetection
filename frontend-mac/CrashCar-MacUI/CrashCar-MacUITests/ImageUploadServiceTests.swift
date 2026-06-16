//
//  ImageUploadServiceTests.swift
//  CrashCar-MacUITests
//
//  Sesión 10 — Tests del servicio de subida a S3, con dependencias inyectadas
//  (`ImageDataFetching` + `AccidentImageStorage`): sin red ni AWS.
//

import XCTest
@testable import CrashCar_MacUI

final class ImageUploadServiceTests: XCTestCase {

    private let baseURL = URL(string: "http://localhost:8000")!

    func testS3KeyFormatIsCorrect() {
        XCTAssertEqual(
            ImageUploadService.s3Key(for: "/accident_images/accident_20260610_123456_abc.jpg"),
            "accidents/accident_20260610_123456_abc.jpg")
        // También funciona con una ruta sin directorio.
        XCTAssertEqual(ImageUploadService.s3Key(for: "accident_x.jpg"), "accidents/accident_x.jpg")
    }

    func testUploadDownloadsThenStoresAndReturnsKey() async throws {
        let fetcher = StubFetcher(data: Data([0x01, 0x02, 0x03]))
        let storage = SpyStorage()
        let service = ImageUploadService(fetcher: fetcher, storage: storage, httpBaseURL: baseURL)

        let key = try await service.uploadAccidentImage(from: "/accident_images/x.jpg")

        XCTAssertEqual(key, "accidents/x.jpg")
        XCTAssertEqual(fetcher.requestedURLs, [URL(string: "http://localhost:8000/accident_images/x.jpg")!])
        XCTAssertEqual(storage.uploaded.first?.path, "accidents/x.jpg")
        XCTAssertEqual(storage.uploaded.first?.data, Data([0x01, 0x02, 0x03]))
    }

    func testUploadPropagatesStorageFailure() async {
        let service = ImageUploadService(fetcher: StubFetcher(data: Data()),
                                         storage: FailingStorage(),
                                         httpBaseURL: baseURL)
        do {
            _ = try await service.uploadAccidentImage(from: "/accident_images/x.jpg")
            XCTFail("Expected the storage failure to propagate")
        } catch {
            // Esperado: el llamador (DetectionViewModel) decide cómo degradar.
        }
    }

    func testGetImageURLDelegatesToStorage() async throws {
        let storage = SpyStorage()
        let service = ImageUploadService(fetcher: StubFetcher(data: Data()),
                                         storage: storage, httpBaseURL: baseURL)

        let url = try await service.getImageURL(for: "accidents/x.jpg")

        XCTAssertEqual(url, SpyStorage.resolvedURL)
        XCTAssertEqual(storage.requestedPaths, ["accidents/x.jpg"])
    }
}

// MARK: - Dobles de prueba

private struct StubFetcher: ImageDataFetching, @unchecked Sendable {
    let data: Data
    private let box = URLBox()

    var requestedURLs: [URL] { box.urls }

    func data(from url: URL) async throws -> Data {
        box.urls.append(url)
        return data
    }

    final class URLBox: @unchecked Sendable { var urls: [URL] = [] }
}

private final class SpyStorage: AccidentImageStorage, @unchecked Sendable {
    static let resolvedURL = URL(string: "https://bucket.s3.amazonaws.com/accidents/x.jpg?sig=abc")!

    private(set) var uploaded: [(path: String, data: Data)] = []
    private(set) var requestedPaths: [String] = []

    func upload(data: Data, toPath path: String) async throws -> String {
        uploaded.append((path, data))
        return path
    }

    func url(forPath path: String) async throws -> URL {
        requestedPaths.append(path)
        return Self.resolvedURL
    }
}

private struct FailingStorage: AccidentImageStorage {
    struct Boom: Error {}
    func upload(data: Data, toPath path: String) async throws -> String { throw Boom() }
    func url(forPath path: String) async throws -> URL { throw Boom() }
}
