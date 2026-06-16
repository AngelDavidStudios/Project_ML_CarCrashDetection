# CrashCar-MacUI — app nativa macOS

App nativa (SwiftUI + AWS Amplify Gen 2) del sistema de detección de accidentes,
sustituta del frontend Next.js. Diseño **LiquidGlass** (macOS 26 Tahoe),
**Approachable Concurrency** (Swift 6.2). Consume el backend FastAPI por WebSocket
y persiste incidentes/puestos de ayuda vial en AppSync/DynamoDB/S3 vía Amplify.

El plan de migración sesión por sesión vive en `../MIGRATION_SWIFT.md`. Las reglas
de Swift no-negociables (concurrencia, 0 warnings, LiquidGlass) están en `../CLAUDE.md`.

## Setup mínimo para un nuevo desarrollador

### Requisitos
- **Xcode 26.5+** (deployment target macOS 26.5 Tahoe).
- **Node** (para el backend Amplify Gen 2 vía `npx ampx`).
- **Python 3** + el backend FastAPI (`../backend/`) para el flujo de detección.
- Acceso a la cuenta AWS del proyecto (credenciales configuradas para `ampx`).

### 1. Backend Amplify (AppSync/DynamoDB/S3 + Cognito)
```bash
cd frontend-mac
npx ampx sandbox --once --outputs-out-dir CrashCar-MacUI/CrashCar-MacUI
```
Esto despliega el stack dev y refresca el `amplify_outputs.json` que la app empaqueta.
Para desarrollo continuo (deploy + watch): `npx ampx sandbox`.

> Tras editar el schema de datos, regenera los modelos con `./scripts/generate-models.sh`
> (NO `ampx generate` a secas: reaplica `nonisolated`, obligatorio por
> `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`).

### 2. Backend FastAPI (detección)
```bash
cd ../backend
source venv/bin/activate
PYTORCH_ENABLE_MPS_FALLBACK=1 uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```
La app apunta a `ws://localhost:8000/ws/detect` (`AppSettings.backendWebSocketURL`).

### 3. Abrir y correr
```bash
open CrashCar-MacUI/CrashCar-MacUI.xcodeproj   # luego ⌘R
```
La primera compilación es lenta (grafo SPM de Amplify).

### Gotchas de configuración (no romper)
- **Keychain Sharing obligatorio:** el entitlement `keychain-access-groups`
  (`CrashCar-MacUI.entitlements`) es imprescindible para Amplify Auth en macOS;
  sin él el login se cuelga (`errSecMissingEntitlement -34018`).
- **App Sandbox + red:** `ENABLE_APP_SANDBOX = YES` **y** `ENABLE_OUTGOING_NETWORK_CONNECTIONS = YES`
  (Debug+Release); si falta lo segundo, AppSync/WebSocket fallan con CFNetwork -1003.
- **Redirect URI de Google = el de Cognito** (`https://<dominio>.auth.<region>.amazoncognito.com/oauth2/idpresponse`),
  registrado en Google Cloud Console; si falta → `Error 400: redirect_uri_mismatch`.

## Tests

```bash
cd CrashCar-MacUI
# Unit (el scheme CLI solo auto-incluye UITests → usar -only-testing):
xcodebuild test -scheme CrashCar-MacUI -destination 'platform=macOS' \
  -only-testing:CrashCar-MacUITests
```
- **Suites herméticas** (ViewModels con mocks, WebSocket, i18n, notificaciones,
  `FramePerformanceTests`): corren sin red ni AWS.
- **Suite E2E** (`CrashCar-MacUITests/Integration/EndToEndTests.swift`): contra AWS
  dev real. Solo corre con `npx ampx sandbox` activo y las env vars:
  ```bash
  RUN_E2E=1 E2E_USERNAME=<usuario-cognito> E2E_PASSWORD=<password> \
    xcodebuild test -scheme CrashCar-MacUI -destination 'platform=macOS' \
    -only-testing:CrashCar-MacUITests/EndToEndTests
  ```
  Sin esas variables hace `XCTSkip` (no rompe `⌘U`). Requiere un **usuario nativo de
  Cognito** (no Google: un host de tests no puede iniciar el login federado interactivo).
- **Checklist E2E manual** (flujo con login Google + FastAPI): `E2E_CHECKLIST.md`.

## Entorno de producción

Amplify **Gen 2** NO usa `amplify env add` (eso es Gen 1). Producción se despliega
con `npx ampx` sobre una rama de prod (CI/CD de Amplify Hosting) o un sandbox dedicado,
y se actualiza el `amplify_outputs.json` empaquetado en la app para apuntar a ese stack.

> El deploy a AWS lo ejecuta el responsable del proyecto. Confirmar el comando exacto
> (rama/pipeline) antes de promover, ya que crea/modifica infraestructura en la nube.
