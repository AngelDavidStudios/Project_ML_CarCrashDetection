//
//  AmplifyInitTests.swift
//  CrashCar-MacUITests
//
//  Sesión 1 — verifica que Amplify Gen 2 se inicializa correctamente.
//

import XCTest
import Amplify
@testable import CrashCar_MacUI

final class AmplifyInitTests: XCTestCase {

    /// El host de los tests unitarios lanza la app, cuyo `init()` ya llama a
    /// `Amplify.configure(with: .amplifyOutputs)`. Por eso aquí NO se vuelve a
    /// configurar (lanzaría `ConfigurationError.amplifyAlreadyConfigured`):
    /// se comprueba que la configuración previa quedó activa.

    /// `amplify_outputs.json` debe estar incluido en el bundle de la app.
    func testAmplifyOutputsBundled() throws {
        let url = Bundle.main.url(forResource: "amplify_outputs", withExtension: "json")
            ?? Bundle(for: Self.self).url(forResource: "amplify_outputs", withExtension: "json")
        XCTAssertNotNil(url, "amplify_outputs.json no está incluido en el bundle.")
    }

    /// Si Amplify está configurado y el plugin de Auth cargado, `fetchAuthSession`
    /// resuelve (sesión no autenticada) sin lanzar — prueba indirecta de que
    /// `configure` tuvo éxito en el arranque de la app.
    func testAuthPluginLoaded() async throws {
        let session = try await Amplify.Auth.fetchAuthSession()
        XCTAssertFalse(session.isSignedIn,
                       "Sin login previo la sesión debe estar no autenticada.")
    }
}
