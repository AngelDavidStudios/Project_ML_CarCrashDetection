//
//  Localizer.swift
//  CrashCar-MacUI
//
//  Sesión 11 — Resolución de strings localizados FUERA de SwiftUI.
//
//  Las vistas se localizan vía el String Catalog + `\.environment(\.locale)`
//  (cambio de idioma en runtime sin reiniciar). Pero el código que no es una
//  vista (p. ej. las notificaciones del sistema en `NotificationService`) no
//  tiene acceso al entorno SwiftUI, así que resuelve los textos contra el
//  `.lproj` del idioma elegido mediante este helper.
//

import Foundation

/// Resuelve claves del catálogo contra el bundle del idioma seleccionado.
/// `nonisolated` + `Sendable` para usarse desde cualquier dominio de aislamiento.
nonisolated struct Localizer: Sendable {
    private let bundle: Bundle

    init(language: AppLanguage) {
        if let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            bundle = langBundle
        } else {
            bundle = .main
        }
    }

    /// Inyección directa de un bundle (tests).
    init(bundle: Bundle) {
        self.bundle = bundle
    }

    /// Texto localizado para `key` (usa la propia clave como valor por defecto).
    func string(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: nil)
    }

    /// Formatea una clave con argumentos posicionales (`%@`).
    func format(_ key: String, _ args: CVarArg...) -> String {
        let template = bundle.localizedString(forKey: key, value: key, table: nil)
        return String(format: template, arguments: args)
    }
}
