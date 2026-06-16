//
//  Formatters.swift
//  CrashCar-MacUI
//
//  Sesión 12 — Utilidades de formateo compartidas (Clean Code: una sola fuente
//  de verdad). Antes, el formateo de un score de confianza (0…1) a porcentaje
//  estaba duplicado en `DetectionViewModel`, `PendingVerificationView`,
//  `IncidentDetailView` y `NotificationService`.
//

import Foundation

extension Double {
    /// Formatea un score de confianza (0…1) como porcentaje entero, p. ej. `0.97` → `"97%"`.
    /// Value type → utilizable desde cualquier dominio de aislamiento sin anotación.
    var asPercent: String {
        "\(Int((self * 100).rounded()))%"
    }
}
