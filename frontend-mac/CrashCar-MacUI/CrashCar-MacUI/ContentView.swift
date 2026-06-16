//
//  ContentView.swift
//  CrashCar-MacUI
//
//  Sesión 3 — Gate de autenticación: login ↔ app.
//  Sesión 4 — La app autenticada monta el shell real (`MainShellView`:
//  NavigationSplitView + LiquidGlass).
//

import SwiftUI

struct ContentView: View {
    @StateObject private var auth = AuthViewModel()
    @StateObject private var settings = AppSettings.shared
    @State private var notificationCoordinator = NotificationCoordinator()

    var body: some View {
        Group {
            if auth.isAuthenticated {
                MainShellView()
            } else {
                LoginView()
            }
        }
        .environmentObject(auth)
        .environmentObject(settings)
        // Cambio de idioma en runtime: el String Catalog resuelve los textos según
        // el locale del entorno, así que cambiar `settings.language` re-renderiza
        // toda la UI en EN/ES sin reiniciar la app (no se altera el idioma del proceso).
        .environment(\.locale, Locale(identifier: settings.language.rawValue))
        .task { await auth.checkSession() }
        .task {
            notificationCoordinator.install()
            await NotificationService.shared.requestAuthorization()
        }
    }
}

#Preview {
    ContentView()
}
