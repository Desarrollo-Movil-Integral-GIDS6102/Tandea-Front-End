# Índice de Documentación de Módulos y Frontend — Tandea

Este directorio centraliza la documentación técnica de la arquitectura de la aplicación móvil (Flutter) y el backend (NestJS + Fastify + Drizzle ORM) de **Tandea**.

---

## 📂 Estructura de Documentación

| Documento | Descripción |
| :--- | :--- |
| [**`componentes-reutilizables.md`**](./componentes-reutilizables.md) | Catálogo de widgets compartidos, botones reutilizables y componentes de UI con ejemplos de uso. |
| [**`modulo-auth.md`**](./modulo-auth.md) | Documentación técnica del módulo de Autenticación (Bienvenida, Login, Registro, validaciones y sesión). |
| [**`modulo-tandas.md`**](./modulo-tandas.md) | Documentación de Gestión de Tandas (Crear tanda, Unirse con código, Seleccionar número, Compartir código y Mis tandas). |
| [**`modulo-pagos.md`**](./modulo-pagos.md) | Documentación del flujo de Pagos (Registrar pago con selector de método, validaciones híbridas, entidades y repositorio). |
| [**`pagos.md`**](./pagos.md) | Pantalla Registrar pago (AP-03): flujo de datos, campos enviados y mensajes de error. |
| [**`modulo-admin.md`**](./modulo-admin.md) | Documentación del Dashboard y funciones administrativas globales. |
| [**`plan-implementacion-pago-ap03.md`**](./plan-implementacion-pago-ap03.md) | Guía técnica paso a paso para implementar la tarea `SP-2-[FE-PAGO] Pantalla Registrar pago (AP-03)` y `SP-2-[BE-PAGO] POST /api/v1/pagos`. |

---

## 🏛️ Arquitectura General del Frontend (Clean Architecture Feature-First)

El proyecto Flutter (`Tandea-Front-End`) sigue **Clean Architecture** estructurado por funcionalidades (*feature-first*):

```text
lib/
├── core/                       # Código transversal y compartido
│   ├── constants/              # ApiConstants, AppColors, AppConstants
│   ├── errors/                 # Exceptions y Failures de dominio
│   ├── network/                # ApiClient, DioClient, interceptores de JWT
│   ├── routes/                 # AppRouter (go_router) con guards de sesión
│   ├── theme/                  # AppTheme (paleta, tipografía, estilos)
│   ├── utils/                  # Formatters y validadores genéricos
│   └── widgets/                # Widgets genéricos reutilizables (PrimaryButton, SecondaryButton)
├── features/                   # Módulos del negocio
│   ├── auth/                   # Autenticación y bienvenida
│   ├── tandas/                 # Creación, unión y visualización de tandas
│   ├── pagos/                  # Registro, cálculo y comprobantes de pago
│   ├── entregas/               # Entrega de fondos y turnos de cobro
│   ├── notificaciones/         # Push notifications y avisos
│   ├── usuarios/               # Perfil y estado del usuario
│   └── admin/                  # Métricas y moderación global
└── injection/                  # Contenedor de Inyección de Dependencias (GetIt)
```

Cada *feature* se subdivide en tres capas estrictas:
1. **`domain/`**: Entidades puras de negocio, excepciones y contratos abstractos de repositorio (`Repository`).
2. **`data/`**: Modelos DTO (`Model`), mapeadores y fuentes de datos remotas (`RemoteDataSource`) conectadas vía `ApiClient` (Dio).
3. **`presentation/`**: Gestores de estado (`ChangeNotifierProvider`), pantallas (`screens/`) y componentes visuales específicos (`widgets/`).
