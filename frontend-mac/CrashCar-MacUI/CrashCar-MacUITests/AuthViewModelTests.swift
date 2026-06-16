//
//  AuthViewModelTests.swift
//  CrashCar-MacUITests
//
//  Sesión 3 — Tests del estado de autenticación usando un `MockAuthService`,
//  sin red ni Cognito (no dependen del entorno AWS).
//

import XCTest
import AuthenticationServices
@testable import CrashCar_MacUI

@MainActor
final class AuthViewModelTests: XCTestCase {

    /// Doble de prueba de `AuthServicing`: no toca red, devuelve un estado fijo.
    private struct MockAuthService: AuthServicing {
        let signedIn: Bool
        var user = AuthenticatedUser(userId: "mock-id", username: "mock@example.com")

        func signIn(presentationAnchor: ASPresentationAnchor?) async throws -> Bool { signedIn }
        func signOut() async {}
        func isSignedIn() async -> Bool { signedIn }
        func currentUser() async -> AuthenticatedUser? { signedIn ? user : nil }
    }

    func testInitialStateIsUnauthenticated() {
        let vm = AuthViewModel(authService: MockAuthService(signedIn: false))
        XCTAssertFalse(vm.isAuthenticated)
        XCTAssertNil(vm.currentUser)
    }

    func testCheckSessionSetsAuthenticatedWhenSignedIn() async {
        let vm = AuthViewModel(authService: MockAuthService(signedIn: true))
        await vm.checkSession()
        XCTAssertTrue(vm.isAuthenticated)
        XCTAssertEqual(vm.currentUser?.username, "mock@example.com")
    }

    func testCheckSessionStaysUnauthenticatedWhenSignedOut() async {
        let vm = AuthViewModel(authService: MockAuthService(signedIn: false))
        await vm.checkSession()
        XCTAssertFalse(vm.isAuthenticated)
        XCTAssertNil(vm.currentUser)
    }

    func testSignOutClearsUser() async {
        let vm = AuthViewModel(authService: MockAuthService(signedIn: true))
        await vm.checkSession()
        await vm.signOut()
        XCTAssertFalse(vm.isAuthenticated)
        XCTAssertNil(vm.currentUser)
    }
}
