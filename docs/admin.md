# Módulo Administrador Global (`FE-ADMIN`) — Tandea

El módulo **Administrador Global** (`lib/features/admin/`) implementa las capacidades de supervisión analítica (AP-11), gestión de usuarios y tandas de la plataforma, así como la auditoría y resolución de casos reportados (disputas) del **Sprint 4**.

---

## 🏛️ Arquitectura (Clean Architecture)

El módulo se divide en las tres capas estándar del proyecto:

### 1. Capa de Dominio (`lib/features/admin/domain/`)
* **Entidades (`entities/`)**:
  * `AdminMetricasEntity`, `ConteoUsuarios`, `ConteoTandas`, `MontoMensual` (`admin_metricas_entity.dart`): modela los indicadores globales de la plataforma y la serie histórica mensual para `fl_chart`.
  * `AdminUsuarioEntity` (`admin_usuario_entity.dart`): representa un usuario registrado con su estado (`active`), rol (`usuario` / `admin_global`) y regla de negocio `puedeSuspenderse`.
  * `AdminDisputaEntity` (`admin_disputa_entity.dart`): representa un caso o disputa reportada (`ABIERTA`, `EN_REVISION`, `RESUELTA`, `DESCARTADA`).
  * `AdminDisputaDetalleEntity`, `BitacoraEntradaEntity`, `EventoLineaTiempoCaso`, `TipoEventoCaso` (`admin_disputa_detalle_entity.dart`): consolida el detalle de una disputa, su pago (`PagoEntity`) o entrega (`EntregaEntity`), la bitácora de auditoría (`audit_log`) y construye la **línea de tiempo cronológica**.
* **Repositorio (`repositories/admin_repository.dart`)**:
  * Contrato `AdminRepository` con los métodos:
    * `obtenerMetricas()`
    * `buscarUsuarios({String? q, bool? active})`
    * `suspenderUsuario(int idUser, {String? motivo})`
    * `listarTandasAdmin({String? search, String? status})`
    * `listarDisputas({String? status, int? idTanda})`
    * `obtenerDetalleDisputa(int idDispute)`
    * `resolverDisputa({required int idDispute, required String accion, required String notas})`

### 2. Capa de Datos (`lib/features/admin/data/`)
* **Modelos DTO (`models/`)**:
  * `AdminMetricasModel`, `AdminUsuarioModel`, `AdminDisputaModel`, `AdminDisputaDetalleModel`.
* **DataSource Remoto (`datasources/admin_remote_data_source.dart`)**:
  * `AdminRemoteDataSourceImpl`: consume los endpoints REST reales mediante `ApiClient` y transforma errores con `NetworkErrorHandler`.
  * En `obtenerDetalleDisputa(idDispute)`, combina `GET /admin/disputas/:id` con `GET /pagos/:idPayment` o `GET /entregas/:idPayout` cuando están presentes.
* **Implementación de Repositorio (`repositories/admin_repository_impl.dart`)**:
  * `AdminRepositoryImpl`: encapsula las respuestas en `Result<T>` (`Success` / `Error`).

### 3. Capa de Presentación (`lib/features/admin/presentation/`)
* **State Management (`providers/admin_provider.dart`)**:
  * `AdminProvider`: gestiona el estado reactivo de métricas, listas de usuarios, tandas y disputas, término de búsqueda con filtrado, suspensión inmediata de usuarios, carga de detalle de disputa y validación del formulario de resolución (`puedeConfirmarResolucion`).

---

## 📱 Pantallas y Rutas

### 1. `AdminDashboardScreen` (`admin_dashboard_screen.dart`)
* **Ruta en GoRouter**: `/admin` (`RouteNames.admin`)
* **Restricción de Rol**: Verifica mediante `AuthSessionProvider` (`isAdminGlobal` / `role.isAdminGlobal`) que el panel solo sea visible si el rol del JWT es `admin_global`. Si otro rol intenta renderizar la pantalla, muestra la vista de acceso restringido (`Key('admin_acceso_restringido')`).
* **Métricas Globales y Gráfica (`AP-11`)**:
  * Tarjetas KPI con datos reales de `GET /api/v1/admin/metricas`:
    * **Total Usuarios**: activos vs suspendidos.
    * **Total Tandas**: activas, pendientes, finalizadas y suspendidas.
    * **Monto total gestionado**: formateado en MXN con `formatearMonedaMxn`.
    * **Disputas pendientes**: conteo de casos abiertos o en revisión.
  * **Gráfica mensual (`fl_chart`)**: `BarChart` (`Key('admin_metricas_bar_chart')`) alimentado por `montoPorMes` (últimos 12 meses), con tooltips en MXN y etiquetas de mes legibles.
* **Gestión con Pestañas (`Usuarios` / `Tandas` / `Casos`) y `SearchBar` con Debounce**:
  * Buscador (`Key('admin_search_bar')`) con **debounce de 400 ms** que filtra la pestaña activa.
  * **Pestaña Usuarios**: muestra nombre, correo, rol, chip `Activo` / `Suspendido` y botón **Suspender** (para usuarios activos no administradores). Al pulsar Suspender, muestra un `AlertDialog` de confirmación con motivo opcional y actualiza inmediatamente el estado en la lista.
  * **Pestaña Tandas**: lista las tandas de la plataforma con monto, participantes, periodicidad, código e indicador de estado.
  * **Pestaña Casos**: lista las disputas reportadas y navega al detalle al seleccionar un caso.

### 2. `AdminCasoDetalleScreen` (`admin_caso_detalle_screen.dart`)
* **Ruta en GoRouter**: `/admin/disputas/:id` (`RouteNames.adminDisputaDetail` / `RouteNames.adminDisputaDetalle(id)`)
* **Línea de tiempo del caso (`Key('caso_linea_tiempo')`)**:
  * Muestra en orden cronológico:
    1. **Pago / Entrega**: montos (transferencia, efectivo, total) y método.
    2. **Confirmaciones**: confirmación del participante, confirmación/rechazo del organizador y verificación OCR.
    3. **Evidencias**: URL del comprobante adjunto (`evidenceUrl`) con diálogo de vista previa.
    4. **Reporte y Bitácora (`audit_log`)**: apertura de la disputa, registros de auditoría y notas de resolución.
* **Sección de Resolución (`Key('seccion_resolucion_caso')`)**:
  * Selector obligatorio de las 3 acciones soportadas por el backend:
    * **Mantener** (`mantener`)
    * **Revertir** (`revertir`)
    * **Suspender** (`suspender`)
  * Campo de comentario obligatorio (`Key('input_notas_resolucion')`).
  * Botón **Resolver caso** (`Key('btn_resolver_caso')`): permanece deshabilitado (`onPressed == null`) hasta que se elija una de las 3 opciones y el comentario no esté vacío.

---

## 🔗 Contratos de API Utilizados (`lib/core/constants/api_constants.dart`)

| Método | Endpoint | Descripción |
| :--- | :--- | :--- |
| `GET` | `/api/v1/admin/metricas` | Estadísticas analíticas globales y serie `montoPorMes` (AP-11). |
| `GET` | `/api/v1/admin/usuarios?q=&active=` | Búsqueda y listado de usuarios de la plataforma. |
| `PATCH` | `/api/v1/admin/usuarios/:id/suspender` | Suspensión de cuenta de usuario (`active = false`). |
| `GET` | `/api/v1/tandas?search=&status=&page=1&limit=50` | Listado global de tandas para `admin_global`. |
| `GET` | `/api/v1/admin/disputas?status=&idTanda=` | Listado de casos y disputas reportadas. |
| `GET` | `/api/v1/admin/disputas/:id` | Detalle de disputa y bitácora (`audit_log`). |
| `GET` | `/api/v1/pagos/:idPayment` | Detalle de pago vinculado a la disputa (montos, OCR, evidencia). |
| `GET` | `/api/v1/entregas/:idPayout` | Detalle de entrega vinculada a la disputa. |
| `PATCH` | `/api/v1/admin/disputas/:id/resolver` | Resolución de disputa (`accion`: `mantener` \| `revertir` \| `suspender`, `notas`). |

---

## 🧪 Pruebas Automatizadas

* `test/admin_metricas_test.dart`: valida deserialización de métricas, carga en KPIs y gráfica `fl_chart`, y restricción de acceso exclusiva para `admin_global`.
* `test/admin_gestion_usuarios_casos_test.dart`: valida navegación entre pestañas `Usuarios`, `Tandas` y `Casos`, `SearchBar` con debounce de 400 ms y diálogo de confirmación de suspensión con actualización inmediata.
* `test/admin_caso_detalle_test.dart`: valida el orden cronológico de la línea de tiempo (pagos, confirmaciones, evidencias, reporte y bitácora) y la habilitación condicional del botón de resolución.
