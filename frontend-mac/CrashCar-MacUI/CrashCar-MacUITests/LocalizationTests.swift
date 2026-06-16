//
//  LocalizationTests.swift
//  CrashCar-MacUITests
//
//  Sesión 11 — Verifica la paridad EN/ES del String Catalog compilado y la
//  resolución de algunas claves clave vía `Localizer`.
//
//  El test corre hospedado en la app, así que `Bundle.main` es el bundle de la
//  app y contiene `en.lproj`/`es.lproj` generados desde `Localizable.xcstrings`.
//

import XCTest
@testable import CrashCar_MacUI

final class LocalizationTests: XCTestCase {

    /// Toda clave EN debe tener traducción ES no vacía.
    func testSpanishHasEveryEnglishKey() throws {
        let en = try strings(forLanguage: "en")
        let es = try strings(forLanguage: "es")

        XCTAssertFalse(en.isEmpty, "No se encontró Localizable.strings (en)")
        let missing = Set(en.keys).subtracting(es.keys)
        XCTAssertTrue(missing.isEmpty,
                      "Faltan traducciones ES para: \(missing.sorted().joined(separator: ", "))")

        for (key, value) in es {
            XCTAssertFalse(value.trimmingCharacters(in: .whitespaces).isEmpty,
                           "Traducción ES vacía para \(key)")
        }
    }

    /// El `Localizer` resuelve contra el `.lproj` del idioma pedido.
    func testLocalizerResolvesSpanishAndEnglish() {
        XCTAssertEqual(Localizer(language: .es).string("Accident detected"), "Accidente detectado")
        XCTAssertEqual(Localizer(language: .en).string("Accident detected"), "Accident detected")
        XCTAssertEqual(Localizer(language: .es).string("Pending Verification"), "Verificación Pendiente")
    }

    /// El formateo posicional conserva los argumentos.
    func testLocalizerFormatSubstitutesArguments() {
        let body = Localizer(language: .es).format("%@ — %@ · %@ confidence", "Colisión", "Quito", "95%")
        XCTAssertTrue(body.contains("Colisión"))
        XCTAssertTrue(body.contains("Quito"))
        XCTAssertTrue(body.contains("95%"))
        XCTAssertTrue(body.contains("de confianza"))
    }

    // MARK: - Helper

    private func strings(forLanguage lang: String) throws -> [String: String] {
        let lprojPath = try XCTUnwrap(Bundle.main.path(forResource: lang, ofType: "lproj"),
                                      "No existe \(lang).lproj en el bundle")
        let bundle = try XCTUnwrap(Bundle(path: lprojPath))
        let url = try XCTUnwrap(bundle.url(forResource: "Localizable", withExtension: "strings"),
                                "No existe Localizable.strings para \(lang)")
        return try XCTUnwrap(NSDictionary(contentsOf: url) as? [String: String])
    }
}
