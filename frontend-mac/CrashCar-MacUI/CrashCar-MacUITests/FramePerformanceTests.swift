//
//  FramePerformanceTests.swift
//  CrashCar-MacUITests
//
//  Sesión 12 — Performance del hot-path de render: decodificar un frame JPEG
//  base64 (lo que llega por el WebSocket en cada frame) a `CGImage`.
//
//  Objetivo del plan de migración: < 16 ms por frame (60 FPS). Este test NO
//  necesita red ni AWS — genera un JPEG sintético del tamaño típico de un frame
//  de CCTV (1280×720) y mide `WebSocketService.decodeFrame(base64:)`.
//

import XCTest
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
@testable import CrashCar_MacUI

final class FramePerformanceTests: XCTestCase {

    /// JPEG base64 de 1280×720 generado una sola vez para todas las iteraciones.
    private lazy var sampleFrameBase64: String = Self.makeSampleJPEGBase64(width: 1280, height: 720)

    /// El frame de ejemplo decodifica a un `CGImage` válido (corrección, no perf).
    func testDecodeFrameProducesImage() throws {
        let image = try WebSocketService.decodeFrame(base64: sampleFrameBase64)
        XCTAssertEqual(image.width, 1280)
        XCTAssertEqual(image.height, 720)
    }

    /// Mide la latencia de decodificación. `measure` reporta el tiempo medio en
    /// el navegador de tests; el objetivo operativo es < 16 ms por frame.
    func testDecodeFramePerformance() throws {
        let base64 = sampleFrameBase64
        measure {
            for _ in 0..<10 {
                _ = try? WebSocketService.decodeFrame(base64: base64)
            }
        }
    }

    // MARK: - Helpers

    /// Crea un JPEG sintético (gradiente) y lo devuelve como base64.
    private static func makeSampleJPEGBase64(width: Int, height: Int) -> String {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return ""
        }
        // Relleno simple para tener contenido que comprimir.
        context.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let cgImage = context.makeImage() else { return "" }

        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(
            data, UTType.jpeg.identifier as CFString, 1, nil) else {
            return ""
        }
        CGImageDestinationAddImage(dest, cgImage, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return "" }
        return (data as Data).base64EncodedString()
    }
}
