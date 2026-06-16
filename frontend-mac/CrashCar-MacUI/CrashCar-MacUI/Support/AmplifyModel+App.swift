//
//  AmplifyModel+App.swift
//  CrashCar-MacUI
//
//  Sesión 7 — Conformidades de UI sobre los modelos generados de Amplify.
//
//  El `Model` de Amplify expone `id` pero no conforma `Identifiable`, que SwiftUI
//  necesita para `Table`, `ForEach` y `.sheet(item:)`. Se añade aquí (fuera de los
//  ficheros generados, que regenera `generate-models.sh`). `nonisolated` porque
//  los modelos son `nonisolated` bajo `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
//

import Foundation

nonisolated extension Incident: Identifiable {}

nonisolated extension TrafficAidPost: Identifiable {}
