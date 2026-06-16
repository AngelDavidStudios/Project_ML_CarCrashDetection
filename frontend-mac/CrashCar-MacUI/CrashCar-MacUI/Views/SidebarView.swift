//
//  SidebarView.swift
//  CrashCar-MacUI
//
//  Sesión 4 — Sidebar del shell. Espejo del `app-sidebar.tsx` del Next.js:
//  header con la marca, grupos de navegación y footer con usuario + idioma +
//  logout. En macOS 26 el sidebar recibe LiquidGlass automáticamente — no se
//  añaden fondos manuales que lo anulen.
//

import SwiftUI

struct SidebarView: View {
    @Binding var selection: AppSection?
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var settings: AppSettings

    /// Secciones navegables, expuestas para el sidebar y los tests.
    let sections = AppSection.allCases

    var body: some View {
        List(selection: $selection) {
            ForEach(AppSection.Group.allCases) { group in
                Section(LocalizedStringKey(group.title)) {
                    ForEach(sections(in: group)) { section in
                        Label(LocalizedStringKey(section.title), systemImage: section.systemImage)
                            .tag(section)
                    }
                }
            }
        }
        .navigationTitle("Crash Detection ML")
        .safeAreaInset(edge: .bottom) { footer }
    }

    private func sections(in group: AppSection.Group) -> [AppSection] {
        sections.filter { $0.group == group }
    }

    /// Footer: avatar + usuario, selector de idioma y logout, agrupados como una
    /// unidad visual glass.
    private var footer: some View {
        GlassEffectContainer {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 1) {
                        ((auth.currentUser?.username).map { Text(verbatim: $0) } ?? Text("Guest"))
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Text("Operator")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }

                Picker("Language", selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Button {
                    Task { await auth.signOut() }
                } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(auth.isBusy)
            }
            .padding(12)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
        }
        .padding(8)
    }
}

#Preview {
    NavigationSplitView {
        SidebarView(selection: .constant(.detection))
            .environmentObject(AuthViewModel())
            .environmentObject(AppSettings())
    } detail: {
        Text("Detail")
    }
}
