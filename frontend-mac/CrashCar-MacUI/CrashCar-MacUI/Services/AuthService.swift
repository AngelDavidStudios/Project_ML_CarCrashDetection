//
//  AuthService.swift
//  CrashCar-MacUI
//
//  Sesión 3 — Autenticación (Cognito Managed Login + Google OAuth) vía Amplify Gen 2.
//
//  Concurrencia: el protocolo es `@MainActor` porque el `presentationAnchor`
//  (NSWindow / ASPresentationAnchor) vive en el main actor. Todo es `async` —
//  sin DispatchQueue ni completion handlers.
//

import Foundation
import Amplify
import AuthenticationServices

/// Usuario autenticado desacoplado del `AuthUser` de Amplify para poder mockear
/// en tests sin depender del plugin ni de la red.
///
/// `Sendable` para cruzar dominios de aislamiento sin copias inseguras.
struct AuthenticatedUser: Sendable, Equatable {
    let userId: String
    let username: String
}

/// Abstracción sobre `Amplify.Auth` que permite inyectar una implementación
/// falsa en los tests unitarios (`MockAuthService`) sin tocar red.
@MainActor
protocol AuthServicing {
    /// Abre la Managed Login (Google aparece como opción configurada en Console)
    /// anclada a `presentationAnchor`. Devuelve si la sesión quedó iniciada.
    func signIn(presentationAnchor: ASPresentationAnchor?) async throws -> Bool
    /// Cierra la sesión actual (local + federada).
    func signOut() async
    /// `true` si hay una sesión válida persistida en Keychain.
    func isSignedIn() async -> Bool
    /// Usuario actual, o `nil` si no hay sesión.
    func currentUser() async -> AuthenticatedUser?
}

/// Implementación real contra Cognito (Managed Login + Google) vía Amplify Gen 2.
/// `ASWebAuthenticationSession` captura el redirect `crashdetector://oauth2redirect`
/// automáticamente en macOS — no hace falta manejar `onOpenURL`.
struct AmplifyAuthService: AuthServicing {

    /// `nonisolated` para poder usarse como argumento por defecto de
    /// `AuthViewModel.init` (los valores por defecto se evalúan sin aislamiento).
    /// El struct no tiene estado, así que es seguro.
    nonisolated init() {}

    func signIn(presentationAnchor: ASPresentationAnchor?) async throws -> Bool {
        let result = try await Amplify.Auth.signInWithWebUI(presentationAnchor: presentationAnchor)
        return result.isSignedIn
    }

    func signOut() async {
        let result = await Amplify.Auth.signOut()
        Amplify.Logging.info("SignOut completado: \(result)")
    }

    func isSignedIn() async -> Bool {
        do {
            return try await Amplify.Auth.fetchAuthSession().isSignedIn
        } catch {
            Amplify.Logging.error("fetchAuthSession falló: \(error)")
            return false
        }
    }

    func currentUser() async -> AuthenticatedUser? {
        do {
            let user = try await Amplify.Auth.getCurrentUser()
            return AuthenticatedUser(userId: user.userId, username: user.username)
        } catch {
            Amplify.Logging.error("getCurrentUser falló: \(error)")
            return nil
        }
    }
}
