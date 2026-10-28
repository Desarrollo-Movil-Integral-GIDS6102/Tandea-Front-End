# 💳 Pagos — Pantalla "Registrar pago" (AP-03 & AP-04)

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
  * **Comprobante de pago (AP-04)**: Selección por cámara o galería, compresión automática, vista previa interactiva, reemplazo y eliminación. Obligatorio en transferencia e híbrido; opcional en efectivo.
  * Botón **"Ya pagué"**: muestra carga y se deshabilita mientras envía o mientras se procesa la imagen (evita doble envío o envíos con comprobante en proceso).
  * Errores en un banner rojo sobre el botón. Al registrarse, muestra un SnackBar y regresa a la pantalla anterior.

---

## 📷 Captura y Subida de Comprobante (AP-04)

### 1. Arquitectura Clean Architecture + Feature First
* **Capa de Dominio (`lib/features/pagos/domain/`)**:
  * `ComprobanteArchivo`: Entidad que encapsula los bytes, nombre y mimeType (`image/jpeg`).
  * `OrigenImagen`: Enum que define la fuente (`camara` o `galeria`).
  * `ComprobanteService`: Contrato abstracto puro en Dart para la captura, selección y compresión.
  * `SeleccionarComprobanteUseCase`: Caso de uso invocado por los providers de presentación.
* **Capa de Datos (`lib/features/pagos/data/services/`)**:
  * `PermissionService` / `PermissionServiceImpl`: Abstracción de `permission_handler` con soporte para Android, iOS y Web.
  * `ImageCompressorService` / `FlutterImageCompressorServiceImpl`: Abstracción de `flutter_image_compress` con fallback resiliente.
  * `ComprobanteServiceImpl`: Orquestador que valida permisos, abre `image_picker`, valida tamaño/vacío y comprime la imagen.
* **Capa de Presentación (`lib/features/pagos/presentation/`)**:
  * `PagoProvider`: Gestiona el ciclo de vida de captura (`procesandoComprobante`, `capturarComprobante`, `eliminarComprobante`, `comprobante`), validaciones previas al envío y cancelación segura.
  * `ComprobantePlaceholder`: Widget reactivo que muestra botones de acción (Cámara y Galería), indicador de carga y optimización, vista previa de imagen (`preview_comprobante`), badge con tamaño en KB, diálogo de zoom interactivo y botones para Cambiar o Eliminar.

### 2. Permisos por Plataforma
* **Android (`android/app/src/main/AndroidManifest.xml`)**:
  * `android.permission.CAMERA`: Acceso a la cámara física.
  * `android.permission.READ_EXTERNAL_STORAGE` (maxSdkVersion 32): Compatibilidad con versiones anteriores de Android.
  * `android.permission.READ_MEDIA_IMAGES`: Acceso a imágenes en Android 13+ (API 33+).
* **iOS (`ios/Runner/Info.plist`)**:
  * `NSCameraUsageDescription`: Explicación clara al usuario para el acceso a la cámara.
  * `NSPhotoLibraryUsageDescription`: Explicación clara al usuario para el acceso a la galería fotográfica.
* **Web / Desktop**:
  * No requieren permisos del sistema móvil; `PermissionServiceImpl` resuelve como concedido directamente para evitar excepciones de plugins no soportados.

### 3. Pipeline de Compresión
* Compresión a formato JPEG con `flutter_image_compress`:
  * Resolución máxima acotada a `1280x1280` px.
  * Calidad de compresión: `80%`.
  * Reducción típica de peso de 4-8 MB a 150-350 KB sin pérdida apreciable de legibilidad del comprobante bancario.
  * Límite estricto de seguridad: 10 MB.

---

## 🔄 Flujo de datos

```
RegistrarPagoScreen
  → PagoProvider.capturarComprobante(origen)
    → SeleccionarComprobanteUseCase(origen)
      → ComprobanteService.obtenerComprobante(origen)
        → PermissionService (verificación/solicitud)
        → ImagePicker (pickImage)
        → ImageCompressorService (compressWithList)
  → PagoProvider.registrarPago(idNumber, cuota)
    → PagoRepository.registrarPago(RegistrarPagoParams)
      → PagoRemoteDataSource.registrarPago()          // Dio + FormData (MultipartFile)
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

| Causa / Respuesta | Mensaje |
| :--- | :--- |
| Permiso de cámara denegado | "No se concedió permiso para usar la cámara. Habilítalo en los ajustes del dispositivo." |
| Permiso de galería denegado | "No se concedió permiso para acceder a la galería. Habilítalo en los ajustes del dispositivo." |
| Comprobante vacío | "El comprobante seleccionado está vacío o no es válido." |
| `400` / `422` | El detalle del backend si viene; si no, "Revisa los montos o el comprobante." |
| `403` | "No puedes registrar pagos en este número." |
| `404` | "No encontramos este turno o su tanda." |
| `409` | "Este pago ya fue registrado." |
| `413` | "El comprobante supera el tamaño máximo de 10 MB." |
| `401` | "Tu sesión expiró. Inicia sesión de nuevo." |
| Sin conexión / `5xx` | "No pudimos enviar tu pago. Intenta de nuevo." |

---

## 🚧 Pendiente y Limitaciones Conocidas

* **Almacenamiento y OCR en backend**: El front-end comprime y envía el archivo binario mediante `multipart/form-data` en el campo `file`. La persistencia definitiva en S3/Cloud Storage y la verificación OCR del comprobante (`ocrVerified`, `ocrDetectedAmount`) son procesadas y resueltas asíncronamente en el backend.
* **Suma híbrida estricta**: Validar centavos en `PagoProvider.sumaValida` contra la cuota (tarjeta complementaria).
* **Diálogo post-registro**: Pantalla o diálogo dedicado "Pago enviado, esperando confirmación".

---

## 🧪 Pruebas

```bash
# Pruebas del módulo de pagos y comprobantes
flutter test test/comprobante_service_test.dart test/comprobante_pago_provider_test.dart test/comprobante_placeholder_widget_test.dart test/pago_provider_test.dart test/registrar_pago_screen_test.dart test/pago_remote_data_source_test.dart test/formato_moneda_test.dart

# Suite completa del Front-End
flutter test
```
