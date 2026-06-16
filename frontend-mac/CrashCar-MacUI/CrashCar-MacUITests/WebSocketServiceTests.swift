//
//  WebSocketServiceTests.swift
//  CrashCar-MacUITests
//
//  Sesión 5 — Tests del protocolo WebSocket y del servicio.
//
//  Todo corre sin red: se ejercita el parsing de mensajes entrantes, la
//  serialización de los salientes, el backoff de reconexión y el decodificado
//  de un frame base64 a `CGImage`.
//

import XCTest
import CoreGraphics
import ImageIO
@testable import CrashCar_MacUI

@MainActor
final class WebSocketServiceTests: XCTestCase {

    // MARK: - Parsing entrante

    func testAccidentMessageParsing() throws {
        let json = """
        {"type":"accident","confidence":0.92,"accident_type":"car_car_accident",
         "location":"-2.17, -79.92","timestamp":1234567890.0}
        """
        let msg = try WebSocketMessage(json: json)
        guard case .accident(let event) = msg else { return XCTFail("esperaba .accident") }
        XCTAssertEqual(event.confidence, 0.92, accuracy: 0.001)
        XCTAssertEqual(event.accidentType, "car_car_accident")
        XCTAssertEqual(event.location, "-2.17, -79.92")
        XCTAssertNil(event.frameNumber)
    }

    func testImageSavedMessageParsing() throws {
        let json = """
        {"type":"image_saved","image_url":"/accident_images/test.jpg",
         "confidence":0.95,"accident_type":"car_bike_accident","timestamp":1234567890.0}
        """
        let msg = try WebSocketMessage(json: json)
        guard case .imageSaved(let event) = msg else { return XCTFail("esperaba .imageSaved") }
        XCTAssertEqual(event.imageUrl, "/accident_images/test.jpg")
        XCTAssertEqual(event.accidentType, "car_bike_accident")
        XCTAssertEqual(event.confidence ?? 0, 0.95, accuracy: 0.001)
    }

    func testFrameMessageParsing() throws {
        let json = #"{"type":"frame","frame":"AAAA","frame_number":42,"progress":0.5,"total_frames":84}"#
        let msg = try WebSocketMessage(json: json)
        guard case .frame(let base64, let frameNumber) = msg else { return XCTFail("esperaba .frame") }
        XCTAssertEqual(base64, "AAAA")
        XCTAssertEqual(frameNumber, 42)
    }

    func testVideoInfoMessageParsing() throws {
        let json = """
        {"type":"video_info","width":1280,"height":720,"fps":24.0,
         "original_fps":30.0,"total_frames":300,"message":"Processing"}
        """
        let msg = try WebSocketMessage(json: json)
        guard case .videoInfo(let info) = msg else { return XCTFail("esperaba .videoInfo") }
        XCTAssertEqual(info.width, 1280)
        XCTAssertEqual(info.height, 720)
        XCTAssertEqual(info.fps, 24.0, accuracy: 0.001)
        XCTAssertEqual(info.totalFrames, 300)
    }

    func testProgressMessageParsing() throws {
        let json = #"{"type":"progress","frame_count":60,"progress":0.2,"message":"Processed 60"}"#
        let msg = try WebSocketMessage(json: json)
        guard case .progress(let event) = msg else { return XCTFail("esperaba .progress") }
        XCTAssertEqual(event.frameCount, 60)
        XCTAssertEqual(event.progress, 0.2, accuracy: 0.001)
    }

    func testProcessingCompleteMessageParsing() throws {
        let json = """
        {"type":"processing_complete","accident_found":true,"total_frames":300,
         "location":"-2.17, -79.92","timestamp":1234567890.0}
        """
        let msg = try WebSocketMessage(json: json)
        guard case .processingComplete(let event) = msg else { return XCTFail("esperaba .processingComplete") }
        XCTAssertTrue(event.accidentFound)
        XCTAssertEqual(event.totalFrames, 300)
    }

    func testReadyAndPongAndError() throws {
        guard case .ready = try WebSocketMessage(json: #"{"type":"ready","message":"go"}"#) else {
            return XCTFail("esperaba .ready")
        }
        guard case .pong = try WebSocketMessage(json: #"{"type":"pong"}"#) else {
            return XCTFail("esperaba .pong")
        }
        guard case .error(let m) = try WebSocketMessage(json: #"{"type":"error","message":"boom"}"#) else {
            return XCTFail("esperaba .error")
        }
        XCTAssertEqual(m, "boom")
    }

    func testConnectedMessageWithoutTypeParsing() throws {
        // El primer mensaje del backend no lleva `type`.
        let json = #"{"message":"Connected to accident detection service","severity":"info"}"#
        let msg = try WebSocketMessage(json: json)
        guard case .connected(let m) = msg else { return XCTFail("esperaba .connected") }
        XCTAssertEqual(m, "Connected to accident detection service")
    }

    func testUnknownTypeThrows() {
        XCTAssertThrowsError(try WebSocketMessage(json: #"{"type":"banana"}"#)) { error in
            XCTAssertEqual(error as? WebSocketMessageError, .unknownType("banana"))
        }
    }

    func testFrameWithoutPayloadThrows() {
        XCTAssertThrowsError(try WebSocketMessage(json: #"{"type":"frame","frame_number":1}"#)) { error in
            XCTAssertEqual(error as? WebSocketMessageError, .missingField("frame"))
        }
    }

    // MARK: - Serialización saliente

    func testPingEncoding() throws {
        let data = try WebSocketMessage.ping.encoded()
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(obj?["type"] as? String, "ping")
    }

    func testProcessVideoEncoding() throws {
        let msg = WebSocketMessage.processVideo(
            url: "/accident_videos/x.mp4",
            cameraName: "Cam 1",
            latitude: -2.17,
            longitude: -79.92,
            cameraId: "cam-1")
        let data = try msg.encoded()
        let obj = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(obj["type"] as? String, "process_video")
        XCTAssertEqual(obj["video_url"] as? String, "/accident_videos/x.mp4")
        XCTAssertEqual(obj["camera_name"] as? String, "Cam 1")
        XCTAssertEqual(obj["latitude"] as? Double, -2.17)
        XCTAssertEqual(obj["camera_id"] as? String, "cam-1")
    }

    func testIncomingMessageNotEncodable() {
        XCTAssertThrowsError(try WebSocketMessage.pong.encoded()) { error in
            XCTAssertEqual(error as? WebSocketMessageError, .notOutgoing)
        }
    }

    // MARK: - Reconexión

    func testReconnectionBackoff() {
        // 1006 (cierre anormal) → 3 s; cualquier otro código → 1 s.
        let delays = WebSocketService.reconnectDelays(for: [1000, 1006, 1011])
        XCTAssertEqual(delays, [1.0, 3.0, 1.0])
        XCTAssertEqual(WebSocketService.reconnectDelay(forCloseCode: 1006), 3.0)
        XCTAssertEqual(WebSocketService.reconnectDelay(forCloseCode: 1000), 1.0)
    }

    // MARK: - Decodificación de frames

    func testBase64FrameDecodesToCGImage() throws {
        let base64 = Self.makeTinyJPEGBase64()
        let image = try WebSocketService.decodeFrame(base64: base64)
        XCTAssertEqual(image.width, 1)
        XCTAssertEqual(image.height, 1)
    }

    func testInvalidBase64Throws() {
        XCTAssertThrowsError(try WebSocketService.decodeFrame(base64: "%%%not-base64%%%")) { error in
            XCTAssertEqual(error as? WebSocketMessageError, .invalidBase64)
        }
    }

    func testInitialState() {
        let service = WebSocketService()
        XCTAssertEqual(service.connectionStatus, .disconnected)
        XCTAssertFalse(service.backendReady)
        XCTAssertNil(service.lastFrame)
    }

    // MARK: - Helpers

    /// Genera un JPEG 1×1 válido y lo devuelve en base64, para no depender de un
    /// literal opaco en el test del decodificado.
    private static func makeTinyJPEGBase64() -> String {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(
            data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 0,
            space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let cgImage = ctx.makeImage()!

        let data = NSMutableData()
        let dest = CGImageDestinationCreateWithData(data, "public.jpeg" as CFString, 1, nil)!
        CGImageDestinationAddImage(dest, cgImage, nil)
        CGImageDestinationFinalize(dest)
        return (data as Data).base64EncodedString()
    }
}
