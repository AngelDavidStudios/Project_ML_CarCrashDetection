//
//  DetectionViewModelTests.swift
//  CrashCar-MacUITests
//
//  Sesión 6 — Tests del coordinador de detección, con mocks inyectados
//  (`IncidentCreating` + `WebSocketServicing`): sin red ni AWS.
//

import XCTest
import Combine
import CoreGraphics
@testable import CrashCar_MacUI

@MainActor
final class DetectionViewModelTests: XCTestCase {

    func testIncidentCreatedOnImageSavedEvent() async throws {
        let incidentVM = MockIncidentViewModel()
        let vm = DetectionViewModel(incidentViewModel: incidentVM,
                                    imageService: MockImageUploader(),
                                    wsService: MockWS(),
                                    notificationService: .shared)

        let event = ImageSavedEvent(
            imageUrl: "/accident_images/x.jpg",
            confidence: 0.9,
            accidentType: "car_car_accident",
            location: "test",
            timestamp: Date().timeIntervalSince1970)

        await vm.handleImageSaved(event)

        XCTAssertEqual(incidentVM.createdIncidents.count, 1)
        XCTAssertEqual(incidentVM.createdIncidents.first?.accidentType, "car_car_accident")
        XCTAssertEqual(incidentVM.createdIncidents.first?.confidenceScore ?? 0, 0.9, accuracy: 0.001)
    }

    func testImageSavedFailureIsLoggedNotThrown() async {
        let incidentVM = MockIncidentViewModel()
        incidentVM.shouldThrow = true
        let vm = DetectionViewModel(incidentViewModel: incidentVM,
                                    imageService: MockImageUploader(),
                                    wsService: MockWS(),
                                    notificationService: .shared)

        await vm.handleImageSaved(ImageSavedEvent(imageUrl: "/x.jpg"))

        XCTAssertEqual(incidentVM.createdIncidents.count, 0)
        XCTAssertTrue(vm.logs.contains { $0.severity == .error })
    }

    func testIncidentCarriesS3KeyWhenUploadSucceeds() async {
        let incidentVM = MockIncidentViewModel()
        let uploader = MockImageUploader(keyToReturn: "accidents/x.jpg")
        let vm = DetectionViewModel(incidentViewModel: incidentVM,
                                    imageService: uploader,
                                    wsService: MockWS(),
                                    notificationService: .shared)

        await vm.handleImageSaved(ImageSavedEvent(
            imageUrl: "/accident_images/x.jpg",
            confidence: 0.9,
            accidentType: "car_car_accident"))

        XCTAssertEqual(uploader.uploadedFrom, ["/accident_images/x.jpg"])
        XCTAssertEqual(incidentVM.createdIncidents.count, 1)
        XCTAssertEqual(incidentVM.createdIncidents.first?.s3ImageKey, "accidents/x.jpg")
    }

    func testUploadFailureDoesNotBlockIncidentCreation() async {
        let incidentVM = MockIncidentViewModel()
        let uploader = MockImageUploader(shouldThrow: true)
        let vm = DetectionViewModel(incidentViewModel: incidentVM,
                                    imageService: uploader,
                                    wsService: MockWS(),
                                    notificationService: .shared)

        await vm.handleImageSaved(ImageSavedEvent(
            imageUrl: "/accident_images/x.jpg",
            confidence: 0.8,
            accidentType: "car_person_accident"))

        // El incidente se crea igual, sin s3ImageKey, y se registra un warning.
        XCTAssertEqual(incidentVM.createdIncidents.count, 1)
        XCTAssertNil(incidentVM.createdIncidents.first?.s3ImageKey)
        XCTAssertTrue(vm.logs.contains { $0.severity == .warning })
    }

    func testInitialState() {
        let vm = DetectionViewModel(incidentViewModel: MockIncidentViewModel(),
                                    imageService: MockImageUploader(),
                                    wsService: MockWS(),
                                    notificationService: .shared)
        XCTAssertEqual(vm.phase, .idle)
        XCTAssertTrue(vm.logs.isEmpty)
        XCTAssertNil(vm.currentFrame)
        XCTAssertNil(vm.selectedVideoURL)
        XCTAssertFalse(vm.isBusy)
    }
}

// MARK: - Mocks

@MainActor
final class MockIncidentViewModel: IncidentCreating {
    private(set) var createdIncidents: [DetectionPayload] = []
    var shouldThrow = false

    func createIncident(from payload: DetectionPayload) async throws -> String {
        if shouldThrow {
            throw NSError(domain: "MockIncident", code: 1)
        }
        createdIncidents.append(payload)
        return UUID().uuidString
    }
}

/// Subidor de imágenes simulado: registra las rutas pedidas y puede fallar.
final class MockImageUploader: AccidentImageUploading, @unchecked Sendable {
    private let keyToReturn: String
    private let shouldThrow: Bool
    private(set) var uploadedFrom: [String] = []

    init(keyToReturn: String = "accidents/mock.jpg", shouldThrow: Bool = false) {
        self.keyToReturn = keyToReturn
        self.shouldThrow = shouldThrow
    }

    func uploadAccidentImage(from localFastAPIUrl: String) async throws -> String {
        uploadedFrom.append(localFastAPIUrl)
        if shouldThrow { throw NSError(domain: "MockImageUploader", code: 1) }
        return keyToReturn
    }
}

@MainActor
final class MockWS: WebSocketServicing {
    let messages: AsyncStream<WebSocketMessage>
    private let continuation: AsyncStream<WebSocketMessage>.Continuation

    private(set) var sentMessages: [WebSocketMessage] = []
    private(set) var connectedURL: URL?
    private(set) var didDisconnect = false

    init() {
        var continuation: AsyncStream<WebSocketMessage>.Continuation!
        self.messages = AsyncStream { continuation = $0 }
        self.continuation = continuation
    }

    var lastFramePublisher: AnyPublisher<CGImage?, Never> {
        Just(nil).eraseToAnyPublisher()
    }

    func connect(to url: URL) { connectedURL = url }
    func disconnect() { didDisconnect = true }
    func send(_ message: WebSocketMessage) { sentMessages.append(message) }

    /// Emite un mensaje entrante hacia el consumidor del stream.
    func emit(_ message: WebSocketMessage) { continuation.yield(message) }
}
