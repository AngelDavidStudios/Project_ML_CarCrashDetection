# Checklist E2E manual — CrashCar-MacUI

Guion reproducible de verificación end-to-end para el flujo que **requiere login
federado interactivo (Google/Managed Login)** y el **backend FastAPI**, que una
suite de tests unitarios no puede automatizar. La parte no-interactiva (CRUD
autenticado contra DynamoDB/S3) está cubierta por `CrashCar-MacUITests/Integration/EndToEndTests.swift`
(gated por `RUN_E2E=1`).

## Prerrequisitos

- [ ] Backend FastAPI corriendo: desde `backend/`, `uvicorn app:app --host 0.0.0.0 --port 8000`
      (en Apple Silicon, `PYTORCH_ENABLE_MPS_FALLBACK=1`).
- [ ] Stack Amplify dev desplegado y alcanzable: desde `frontend-mac/`, `npx ampx sandbox`.
- [ ] `amplify_outputs.json` actualizado en el bundle de la app.
- [ ] App compilada y lanzada desde Xcode (`⌘R`) con destino macOS.
- [ ] Un vídeo de prueba con un accidente visible disponible localmente.

## 1. Autenticación

- [ ] Al abrir la app aparece `LoginView` (gate en `ContentView`).
- [ ] Pulsar "Sign in" abre la Managed Login de Cognito en `ASWebAuthenticationSession`.
- [ ] Elegir Google → completar login → la ventana se cierra sola (redirect capturado).
- [ ] La app pasa a `MainShellView` (sidebar + detalle).
- [ ] **Persistencia:** cerrar y reabrir la app → entra directo sin re-login (sesión en Keychain).

## 2. Detección (sección Detection)

- [ ] Seleccionar el vídeo de prueba (`NSOpenPanel`); se muestra el nombre del archivo.
- [ ] Rellenar nombre de cámara + lat/lng.
- [ ] Iniciar detección: el log muestra `Preparing video…` → `Connecting…` → `Backend ready` → `Detection started`.
- [ ] Los frames anotados se renderizan en vivo (fluidos, sin congelarse).
- [ ] Al detectar un accidente: aparece línea `⚠️ <tipo> — <confianza>%` en el log.
- [ ] Llega una **notificación del sistema macOS** localizada al idioma elegido.
- [ ] Al terminar: `Processing complete — accidents detected` y la barra de progreso llega a 100%.

## 3. Incidente creado (sección Pending Verification)

- [ ] El incidente del accidente aparece en la lista de pendientes.
- [ ] La imagen del accidente se muestra (resuelta desde **S3**; fallback al estático del backend).
- [ ] Tocar la notificación del paso 2 cambia la app a `Pending Verification` (deep link).

## 4. Verificación

- [ ] Abrir el detalle del incidente (`IncidentDetailView`).
- [ ] Rellenar el formulario (`IncidentVerificationForm`): tipo, severidad, notas, ¿respuesta necesaria?
- [ ] Aprobar → el incidente sale de pendientes y `verifiedAt` queda registrado.

## 5. Incidentes en curso (sección Ongoing + MapKit)

- [ ] El incidente aprobado aparece en `Ongoing Incidents`.
- [ ] El mapa (`IncidentMapView`) muestra el pin en la lat/lng correcta.
- [ ] Iniciar respuesta → `responseInitiated` se refleja en la UI.
- [ ] Resolver → `resolvedAt` registrado y el incidente sale de la lista activa.

## 6. Traffic Aid CRUD (sección Traffic Aid)

- [ ] Crear un puesto con todos los campos requeridos → aparece en la lista.
- [ ] Validación: dejar `name`/`contactNumber` vacíos → error de campos requeridos.
- [ ] Editar un puesto (cambio parcial) → se refleja el cambio.
- [ ] Borrar un puesto → desaparece de la lista y de DynamoDB.

## 7. i18n + cierre de sesión

- [ ] Cambiar idioma EN↔ES en el footer del sidebar → la UI se re-localiza **sin reiniciar**.
- [ ] Las notificaciones nuevas salen en el idioma seleccionado (vía `Localizer`).
- [ ] Cerrar sesión → vuelve a `LoginView`; reabrir la app exige login de nuevo.

## 8. Performance (objetivo del plan)

- [ ] Render de frames fluido a ojo durante la detección (sin tirones).
- [ ] Métrica automatizada de referencia: `FramePerformanceTests.testDecodeFramePerformance`
      decodifica un frame 1280×720 muy por debajo de 16 ms (60 FPS).

## Limpieza tras la prueba

- [ ] Borrar de DynamoDB/S3 los registros e imágenes de prueba creados (o usar el
      cleanup `tearDown` de la suite E2E automatizada).
