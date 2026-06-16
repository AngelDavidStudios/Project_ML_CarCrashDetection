//
//  CrashCar_MacUIApp.swift
//  CrashCar-MacUI
//
//  Created by Angel on 10/6/26.
//

import SwiftUI
import Amplify
import AWSCognitoAuthPlugin
import AWSAPIPlugin
import AWSS3StoragePlugin

@main
struct CrashCar_MacUIApp: App {

    init() {
        Self.configureAmplify()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    /// Registra los plugins de Amplify Gen 2 y carga la configuración
    /// desde `amplify_outputs.json` (generado por `npx ampx sandbox`).
    /// `nonisolated static` para poder invocarse desde `init()` sin saltar
    /// de dominio de aislamiento.
    nonisolated private static func configureAmplify() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
            try Amplify.add(plugin: AWSS3StoragePlugin())
            try Amplify.configure(with: .amplifyOutputs)
            Amplify.Logging.info("Amplify configurado correctamente (Gen 2).")
        } catch {
            assertionFailure("Fallo al configurar Amplify: \(error)")
        }
    }
}
