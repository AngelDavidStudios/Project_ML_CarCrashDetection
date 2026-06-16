//
//  String+App.swift
//  CrashCar-MacUI
//
//  Sesión 12 — Utilidades de String compartidas. Antes, `trimmed` vivía como
//  `private extension` dentro de `TrafficAidViewModel`; se promueve aquí para
//  reutilizarla en validaciones de formularios sin redeclararla (DRY).
//

import Foundation

extension String {
    /// La cadena sin espacios en blanco ni saltos de línea al inicio/fin.
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
