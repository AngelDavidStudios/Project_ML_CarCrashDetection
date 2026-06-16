//
//  AuthViewModel.swift
//  CrashCar-MacUI
//
//  Sesión 3 — Estado de autenticación de la app. Corre en `@MainActor` por el
//  aislamiento por defecto del proyecto (Approachable Concurrency).
//

import Foundation
import Combine
import AppKit
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {

    /// `true` cuando hay una sesión Cognito válida. La UI conmuta login ↔ app.
    @Published private(set) var isAuthenticated = false

    /// Usuario autenticado actual (o `nil` si no hay sesión).
    @Published private(set) var currentUser: AuthenticatedUser?

    /// Indica una operación de login/logout en curso (para deshabilitar la UI).
    @Published private(set) var isBusy = false

    /// Mensaje de error del último intento fallido, para mostrarlo en la vista.
    @Published var errorMessage: String?

    private let authService: any AuthServicing

    init(authService: any AuthServicing = AmplifyAuthService()) {
        self.authService = authService
    }

    /// Comprueba si hay sesión persistida al arrancar la app.
    func checkSession() async {
        let signedIn = await authService.isSignedIn()
        isAuthenticated = signedIn
        currentUser = signedIn ? await authService.currentUser() : nil
    }

    /// Abre la Managed Login de Cognito (Google) y actualiza el estado.
    func signIn() async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            let signedIn = try await authService.signIn(presentationAnchor: Self.keyWindow)
            isAuthenticated = signedIn
            currentUser = signedIn ? await authService.currentUser() : nil
        } catch {
            // Incluye la cancelación del usuario (cierra la ventana de Managed Login);
            // se muestra el mensaje y puede reintentar con el botón.
            errorMessage = error.localizedDescription
        }
    }

    /// Cierra la sesión y limpia el estado local.
    func signOut() async {
        isBusy = true
        defer { isBusy = false }
        await authService.signOut()
        isAuthenticated = false
        currentUser = nil
    }

    /// Ventana activa para anclar `ASWebAuthenticationSession` (Managed Login).
    private static var keyWindow: ASPresentationAnchor? {
        NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first
    }
}
