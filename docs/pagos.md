# 💳 Pagos — Pantalla "Registrar pago" (AP-03)

El participante registra el pago de su turno (transferencia, efectivo o híbrido). El pago queda `PENDIENTE` hasta que el organizador lo confirme. Tandea no mueve dinero: solo registra el pago y su comprobante.

---

## 📱 Pantalla `RegistrarPagoScreen`

* **Ruta**: `RouteNames.registrarPago` (`/pagos/nuevo`). Recibe `RegistrarPagoArgs` por `extra`:
  ```dart
  context.push(
    RouteNames.registrarPago,
    extra: const RegistrarPagoArgs(
      nombreTanda: 'Tanda Navideña',
      idNumber: 10,     // id_number del turno del usuario
      numeroTurno: 3,   // número visible (opcional)
      vuelta: 1,        // opcional
      cuota: 1500,      // contributionAmount de la tanda
    ),
  );
  ```
  Cada visita crea su propio `PagoProvider`, así que el formulario empieza limpio.
* **Contenido**:
  * Encabezado con la tanda, el turno/vuelta y el **monto esperado** en MXN (`$1,500.00`).
  * Selector de método (`RadioGroup` + `RadioListTile`): Transferencia, Efectivo e Híbrido.
  * Transferencia/Efectivo: muestra el monto (igual a la cuota). Híbrido: campos "Monto por transferencia" y "Monto en efectivo" con teclado numérico (máximo 2 decimales).
  * Espacio para el comprobante (obligatorio en transferencia e híbrido; opcional en efectivo).
  * Botón **"Ya pagué"**: muestra carga y se deshabilita mientras envía (no permite doble envío).
  * Errores en un banner rojo sobre el botón. Al registrarse, muestra un SnackBar y regresa a la pantalla anterior.

---

## 🔄 Flujo de datos

```
RegistrarPagoScreen
  → PagoProvider.registrarPago(idNumber, cuota)      // estados: inicial / cargando / exito / error
    → PagoRepository.registrarPago(RegistrarPagoParams)
      → PagoRemoteDataSource.registrarPago()          // Dio + FormData
        → POST /api/v1/pagos (multipart/form-data, con JWT)
```

### Campos enviados

| Campo | Transferencia | Efectivo | Híbrido |
| :--- | :--- | :--- | :--- |
| `idNumber` | ✅ | ✅ | ✅ |
| `metodoPago` | `transferencia` | `efectivo` | `hibrido` |
| `transferAmount` | cuota | — | capturado |
| `cashAmount` | — | cuota | capturado |
| `file` | comprobante | opcional | comprobante |

Los montos viajan como texto con 2 decimales exactos (`"600.00"`), redondeados en centavos para evitar errores de punto flotante.

---

## ⚠️ Mensajes de error

| Respuesta | Mensaje |
| :--- | :--- |
| `400` / `422` | El detalle del backend si viene; si no, "Revisa los montos o el comprobante." |
| `403` | "No puedes registrar pagos en este número." |
| `404` | "No encontramos este turno o su tanda." |
| `409` | "Este pago ya fue registrado." |
| `413` | "El comprobante supera el tamaño máximo de 10 MB." |
| `401` | "Tu sesión expiró. Inicia sesión de nuevo." |
| Sin conexión / `5xx` | "No pudimos enviar tu pago. Intenta de nuevo." |

---

## 🚧 Pendiente (otras tarjetas)

* Captura/subida de foto del comprobante (`image_picker`, compresión y vista previa): conectar en `ComprobantePlaceholder.onComprobanteSeleccionado`. Mientras tanto, transferencia e híbrido regresan error del backend por falta de comprobante.
* Deshabilitar "Ya pagué" si la suma híbrida no coincide con la cuota: `PagoProvider.sumaValida`.
* Pantalla/diálogo "Pago enviado, esperando confirmación".
* Botón de entrada desde el detalle de la tanda (AP-06), que obtiene el `idNumber` del usuario en `GET /tandas/:id` (`participantes`).

---

## 🧪 Pruebas

```bash
flutter test test/pago_provider_test.dart test/pago_remote_data_source_test.dart test/registrar_pago_screen_test.dart test/formato_moneda_test.dart
```
