# Módulo de Administración Global — Tandea (Documentación Técnica)

El módulo de Administración Global provee visibilidad analítica y herramientas de supervisión para el usuario con rol `admin_global`, garantizando la transparencia, cumplimiento y resolución de incidentes en la plataforma.

> Ver documentación detallada de arquitectura, entidades, casos de uso y pruebas en [`docs/admin.md`](./admin.md).

---

## 📱 Pantallas (`lib/features/admin/presentation/screens/`)

### 1. `AdminDashboardScreen` (`admin_dashboard_screen.dart`)
* **Ruta en GoRouter**: `/admin`
* **Acceso**: Restringido mediante Guard en `AppRouter` y verificación en pantalla con `AuthSessionProvider` validando que `role == 'admin_global'`.
* **Componentes y Métricas Globales (AP-11)**:
  * **Tarjetas de Estadísticas (KPIs)**:
    * Total de usuarios activos vs suspendidos.
    * Tandas activas, pendientes, finalizadas y suspendidas.
    * Monto total gestionado en la plataforma formateado en MXN (`formatearMonedaMxn`).
    * Disputas pendientes de resolución.
  * **Gráfica Mensual (`fl_chart`)**:
    * `BarChart` alimentado por `montoPorMes` (últimos 12 meses).
  * **Gestión de Usuarios, Tandas y Casos**:
    * `SearchBar` con debounce de 400 ms.
    * Pestañas **Usuarios** (con suspensión y diálogo de confirmación), **Tandas** y **Casos**.

### 2. `AdminCasoDetalleScreen` (`admin_caso_detalle_screen.dart`)
* **Ruta en GoRouter**: `/admin/disputas/:id`
* **Componentes**:
  * Encabezado con estado, tanda, reportante y motivo del caso.
  * **Línea de tiempo cronológica**: pagos/entregas, confirmaciones (participante, organizador y OCR), evidencias (`evidenceUrl`) y bitácora (`audit_log`).
  * **Formulario de resolución**: selector obligatorio (`mantener`, `revertir`, `suspender`) y comentario obligatorio que habilita el botón **Resolver caso**.

---

## 🔗 Endpoints del Backend Vinculados (`Tandea-Back-End`)

* **`GET /api/v1/admin/metricas`**: Calcula y consolida las estadísticas analíticas globales de la plataforma.
* **`GET /api/v1/admin/usuarios?q=&active=`**: Busca y filtra usuarios registrados.
* **`PATCH /api/v1/admin/usuarios/:id/suspender`**: Desactiva el acceso de un usuario (`user.active = false`).
* **`GET /api/v1/tandas?search=&status=`**: Lista las tandas de la plataforma para el administrador global.
* **`GET /api/v1/admin/disputas`**: Lista las quejas o discrepancias entre participantes y organizadores.
* **`GET /api/v1/admin/disputas/:id`**: Obtiene el detalle de la disputa junto con sus entradas de `audit_log`.
* **`PATCH /api/v1/admin/disputas/:id/resolver`**: Resuelve una disputa aplicando la acción `mantener`, `revertir` o `suspender` con notas de auditoría.
