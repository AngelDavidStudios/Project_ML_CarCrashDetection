#!/usr/bin/env bash
#
# generate-models.sh — Regenera los modelos Swift de Amplify Data Gen 2 y
# reaplica el fix de aislamiento requerido por este proyecto.
#
# Contexto: el target Xcode usa SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor
# (Approachable Concurrency). El código que genera `ampx` no lleva anotaciones
# de aislamiento, así que sus tipos quedarían @MainActor por defecto — pero
# Amplify exige que los Model sean `nonisolated`/`Sendable` (conforman a
# Decodable/Model que se usan en contextos nonisolated del SDK).
#
# Por eso, tras generar, se marca `nonisolated` cada declaración de modelo.
# Ejecutar SIEMPRE esto en lugar de `ampx generate ...` a secas.
#
# Uso:
#   cd frontend-mac
#   ./scripts/generate-models.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$HERE/CrashCar-MacUI/CrashCar-MacUI/Models"

echo "→ Generando modelos en $OUT"
npx ampx generate graphql-client-code \
    --format=modelgen \
    --model-target=swift \
    --out "$OUT"

echo "→ Reaplicando 'nonisolated' a los modelos generados"
# Cada substitución es idempotente: una vez aplicada, su patrón ya no coincide.
perl -i -pe '
    s/^(public )(struct \w+: Model \{)/${1}nonisolated $2/;
    s/^(public )(enum \w+: String, EnumPersistable \{)/${1}nonisolated $2/;
    s/^(\s*public )(class Path: ModelPath<)/${1}nonisolated $2/;
    s/^(final public class AmplifyModels:)/nonisolated $1/;
    s/^(extension \w+ \{)$/nonisolated $1/;
    s/^(extension ModelPath where ModelType == \w+ \{)$/nonisolated $1/;
' "$OUT"/*.swift

echo "✓ Modelos generados y anotados. Verificar build con: xcodebuild build -scheme CrashCar-MacUI -destination 'platform=macOS'"
