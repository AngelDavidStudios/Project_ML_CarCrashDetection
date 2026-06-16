//
//  LoginView.swift
//  CrashCar-MacUI
//
//  Sesión 3 — Pantalla de login. El branding del flujo OAuth (logo, colores,
//  textos) se configura en AWS Console → Cognito → Managed Login, no aquí.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 12) {
                Image(systemName: "car.side.rear.and.collision.and.car.side.front")
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(.tint)
                    .symbolRenderingMode(.hierarchical)
                Text("Crash Detector")
                    .font(.largeTitle.bold())
                Text("Real-time road accident monitoring")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task { await auth.signIn() }
            } label: {
                HStack(spacing: 8) {
                    if auth.isBusy {
                        ProgressView().controlSize(.small)
                    }
                    Text(LocalizedStringKey(auth.isBusy ? "Signing in…" : "Sign in with Google"))
                        .fontWeight(.medium)
                }
                .frame(maxWidth: 260)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(auth.isBusy)

            if let errorMessage = auth.errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }
        }
        .padding(48)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
        .frame(width: 560, height: 480)
}
