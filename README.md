# 🌀 Tandea – Frontend Flutter

Aplicación móvil de gestión de ahorro rotativo (tandas) con tres roles de usuario:
**Participante**, **Administrador de Tanda** y **Administrador Global**.

---

## 📐 Arquitectura: Clean Architecture + Feature First

Este proyecto sigue los principios de **Clean Architecture** organizado por **funcionalidades (features)**. Cada feature es un módulo independiente con tres capas estrictamente separadas.

### Estructura de carpetas

```
lib/
├── core/
│   ├── errors/          ← Clases de excepción y Failure personalizados
│   ├── network/         ← Configuración de Dio, interceptores, timeouts
│   ├── theme/           ← ThemeData, colores, tipografía global
│   ├── utils/           ← Helpers, formateadores de fecha/moneda, constantes
│   └── widgets/         ← Widgets reutilizables entre features (botones, loaders)
│
├── injection/           ← injection.dart: registro de dependencias con get_it
│
└── features/
    ├── auth/
    ├── tandas/
    ├── pagos/
    ├── usuarios/
    └── notificaciones/
        │
        ├── data/
        │   ├── datasources/   ← *RemoteDataSource.dart  (llama a la API con Dio)
        │   ├── models/        ← *Model.dart             (fromJson / toEntity)
        │   └── repositories/  ← *RepositoryImpl.dart    (implementa la interfaz)
        │
        ├── domain/
        │   ├── entities/      ← *.dart                  (objeto puro de negocio)
        │   └── repositories/  ← *Repository.dart        (interfaz/contrato)
        │
        └── presentation/
            ├── providers/     ← *Provider.dart          (ChangeNotifier + lógica)
            ├── screens/       ← *Screen.dart            (pantallas completas)
            └── widgets/       ← widgets propios de la feature
```

---

## 🔄 Flujo de datos

```
Screen (UI)
  │  context.watch<PagoProvider>()
  ▼
Provider          → orquesta la lógica, llama al repositorio
  │  PagoRepository (interfaz del dominio)
  ▼
RepositoryImpl    → implementa la interfaz, coordina datasources
  │
  ▼
RemoteDataSource  → hace la petición HTTP con Dio
  │
  ▼
API REST (backend)
```

> La dependencia **siempre apunta hacia el dominio**, nunca hacia afuera.

---

## 📦 Paquetes utilizados

| Paquete | Versión | Uso |
|---|---|---|
| `dio` | ^5.7.0 | Cliente HTTP para consumir la API REST |
| `get_it` | ^8.0.0 | Inyección de dependencias (Singleton) |
| `provider` | ^6.1.2 | Gestión de estado (Observer/ChangeNotifier) |
| `equatable` | ^2.0.5 | Comparación por valor en entidades del dominio |

---

## 📏 Reglas del equipo (OBLIGATORIAS)

### 1. Capas y dependencias

- ✅ `domain/` **NUNCA** importa `dio`, `flutter/material`, `provider` ni ningún paquete de red o UI.
- ✅ `data/` puede importar `dio` y los modelos, pero **NUNCA** importa widgets de `presentation/`.
- ✅ `presentation/` solo se comunica con `domain/repositories/` (la interfaz), **NUNCA** con `data/datasources/` directamente.

### 2. Cómo crear una nueva feature

Sigue este orden **siempre**:

```
1. domain/entities/      → Define la entidad (objeto de negocio puro)
2. domain/repositories/  → Define el contrato (interfaz abstracta)
3. data/models/          → Crea el Model con fromJson() y toEntity()
4. data/datasources/     → Implementa las llamadas HTTP con Dio
5. data/repositories/    → Implementa la interfaz del dominio
6. injection/            → Registra todo en get_it
7. presentation/         → Crea el Provider y las Screens
```

### 3. Nombrado de archivos

| Capa | Ejemplo |
|---|---|
| Entidad | `pago.dart` |
| Interfaz repositorio | `pago_repository.dart` |
| Modelo (DTO) | `pago_model.dart` |
| DataSource | `pago_remote_data_source.dart` |
| Implementación repo | `pago_repository_impl.dart` |
| Provider | `pago_provider.dart` |
| Screen | `registro_pago_screen.dart` |

> **Convención:** `snake_case` para archivos, `PascalCase` para clases. Sin abreviaciones.

### 4. Gestión de estado (Provider)

- Cada feature tiene su propio `*Provider` que extiende `ChangeNotifier`.
- Los estados de carga se modelan con un enum interno:
  ```dart
  enum EstadoCarga { inicial, cargando, exito, error }
  ```
- Usa `context.watch<T>()` solo en el widget raíz de la pantalla.
- Usa `context.select<T, R>()` en widgets hijos para evitar rebuilds innecesarios.
- **PROHIBIDO** llamar `notifyListeners()` dentro del constructor del Provider.

### 5. Manejo de errores

- Los `RemoteDataSource` lanzan excepciones específicas (ej. `ServerException`).
- Los `RepositoryImpl` las capturan con `try/catch` y retornan un `Failure`.
- Los `Provider` exponen el mensaje de error via `String? errorMessage`.

### 6. Inyección de dependencias (`injection.dart`)

- Todo se registra en `lib/injection/injection.dart`.
- Usa `sl.registerLazySingleton` para Dio, DataSources y Repositories.
- Usa `sl.registerFactory` para los Providers (nueva instancia por pantalla).
- **Nunca** instancies dependencias directamente dentro de un widget o Provider.

---

## 🚀 Cómo correr el proyecto

```bash
# Instalar dependencias
flutter pub get

# Correr en modo debug
flutter run

# Correr en dispositivo específico
flutter run -d <device_id>
```

---

## 👥 Roles de usuario

| Rol | Permisos |
|---|---|
| **Participante** | Ver su tanda, registrar pagos, confirmar pagos |
| **Admin de Tanda** | Todo lo anterior + confirmar pagos de participantes, gestionar turnos |
| **Admin Global** | Todo lo anterior + crear/eliminar tandas, gestionar usuarios |
