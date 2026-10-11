# 🌀 Tandea – Frontend Flutter

Aplicación móvil de gestión de ahorro rotativo (tandas) con tres roles de usuario:
**Participante**, **Administrador de Tanda** y **Administrador Global**.

---

## 📐 Arquitectura: Clean Architecture + Feature First

Este proyecto sigue estrictamente los principios de **Clean Architecture** organizado por **funcionalidades (features)**. Cada feature es un módulo independiente con capas estrictamente separadas.

### Estructura del proyecto

```
lib/
├── core/
│   ├── constants/       ← Constantes globales (AppConstants, ApiConstants, AppColors)
│   ├── errors/          ← Clases de Failure y Exception personalizadas
│   ├── network/         ← Cliente DioClient, interceptores, timeouts
│   ├── routes/          ← Configuración centralizada de go_router y RouteNames
│   ├── theme/           ← ThemeData, esquema de colores y tipografía global
│   ├── usecases/        ← Contrato base genérico UseCase<Type, Params>
│   ├── utils/           ← Result<T>, helpers y formateadores
│   └── widgets/         ← Widgets reutilizables entre features
│
├── injection/           ← injection.dart: Service Locator con get_it
│
└── features/
    ├── auth/
    ├── tandas/
    ├── pagos/
    ├── entregas/
    ├── notificaciones/
    └── admin/
        │
        ├── domain/
        │   ├── entities/      ← Entidades puras de negocio (con Equatable)
        │   ├── repositories/  ← Interfaces / contratos abstractos
        │   └── usecases/      ← Casos de uso específicos (ej. IniciarSesionUseCase)
        │
        ├── data/
        │   ├── datasources/   ← *RemoteDataSource.dart (peticiones HTTP con Dio)
        │   ├── models/        ← *Model.dart (DTOs, fromJson, toJson, toEntity)
        │   └── repositories/  ← *RepositoryImpl.dart (implementa el contrato de dominio)
        │
        └── presentation/
            ├── providers/     ← *Provider.dart (gestor de estado con ChangeNotifier)
            ├── screens/       ← *Screen.dart (pantallas completas)
            └── widgets/       ← Componentes visuales exclusivos de la feature
```

---

## 🔄 Flujo de datos en Clean Architecture

```
Screen (UI)
  │  context.watch<PagoProvider>()
  ▼
Provider (Presentation)
  │  ejecuta Caso de Uso
  ▼
UseCase (Domain)
  │  llama al contrato abstracto
  ▼
PagoRepository (Domain Interface)
  │  implementado por
  ▼
PagoRepositoryImpl (Data Layer)
  │  coordina
  ▼
RemoteDataSource (Data Layer)
  │  petición HTTP
  ▼
API REST (Backend)
```

> **Regla de Dependencia:** Las dependencias **siempre apuntan hacia el dominio**, nunca hacia la infraestructura ni hacia la UI.

---

## 📦 Paquetes utilizados

| Paquete | Versión | Uso |
|---|---|---|
| `go_router` | ^18.0.2 | Enrutamiento declarativo y navegación |
| `dio` | ^5.7.0 | Cliente HTTP para consumir la API REST |
| `get_it` | ^8.0.0 | Inyección de dependencias (Service Locator) |
| `provider` | ^6.1.2 | Gestión de estado reactivo (ChangeNotifier) |
| `equatable` | ^2.0.5 | Comparación por valor en entidades del dominio y failures |

---

## 📏 Reglas del equipo (OBLIGATORIAS)

### 1. Capas y dependencias

- ✅ `domain/` **NUNCA** importa `dio`, `flutter/material`, `provider` ni ningún paquete de red o UI.
- ✅ `data/` puede importar `dio` y los modelos, pero **NUNCA** importa widgets ni proveedores de `presentation/`.
- ✅ `presentation/` se comunica a través de **Casos de Uso** o contratos de `domain/`, **NUNCA** con `data/` directamente.

### 2. Flujo de implementación de una nueva feature

Sigue este orden siempre:

```
1. domain/entities/      → Define la entidad pura del negocio (extends Equatable)
2. domain/repositories/  → Define el contrato abstracto
3. domain/usecases/      → Crea el caso de uso que extiende UseCase<T, Params>
4. data/models/          → Crea el Model (DTO) con fromJson() y toEntity()
5. data/datasources/     → Implementa llamadas remotas con DioClient
6. data/repositories/    → Implementa el contrato capturando excepciones y retornando Result<T>
7. injection/            → Registra DataSource, Repo, UseCase y Provider en get_it
8. presentation/         → Crea el Provider, Screen y Widgets asociados
9. core/routes/          → Registra la nueva ruta en AppRouter
```

### 3. Manejo de resultados y errores

- Los `RemoteDataSource` lanzan excepciones específicas (`ServerException`, `NetworkException`).
- Los `RepositoryImpl` capturan las excepciones y retornan `Result<T>` (`Success(data)` o `Error(failure)`).
- Los `Provider` consumen el `Result<T>` mediante pattern matching con `.when(...)` y notifican el estado a la UI.

### 4. Lints y análisis estricto

El proyecto cuenta con reglas estrictas configuradas en `analysis_options.yaml`:
- Tipado estricto habilitado (`strict-casts`, `strict-inference`, `strict-raw-types`).
- Reglas de inmutabilidad (`prefer_const_constructors`, `prefer_final_locals`, etc.).
- Sin `dynamic` implícito ni llamadas dinámicas inseguras.

---

## 🚀 Cómo correr el proyecto

```bash
# Instalar dependencias
flutter pub get

# Verificar análisis estricto de código
flutter analyze

# Correr en modo debug
flutter run
```
