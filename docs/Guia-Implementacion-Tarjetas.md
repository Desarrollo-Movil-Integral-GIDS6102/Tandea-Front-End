# Guía de Implementación de Tarjetas — Tandea

Este documento detalla el análisis técnico, flujo de trabajo y arquitectura para la implementación de las siguientes tarjetas del backlog, tomando como referencia los lineamientos de [`Guía del Trello de Tandea.html`](./Guía%20del%20Trello%20de%20Tandea.html) y la planificación de [`Backlog Tandea.html`](./Backlog%20Tandea.html).

---

## 📌 Contexto y Reglas del Proyecto

1. **Jerarquía y Prioridad según la Guía del Trello**:
   - **`BE` (Backend y Nube)**: Endpoints, servicios, entidades de dominio, puertos y adaptadores en NestJS + Fastify + Drizzle ORM.
   - **`INT` (Integraciones)**: Servicios externos como correo (Resend/SendGrid), OCR (Google Vision), Firebase Cloud Messaging.
   - **Flujo irrenunciable**: *Crear tanda, unirse, pagar, confirmar y entregar* nunca se recortan bajo ninguna circunstancia.
   - **Orden de recorte**: Los correos de confirmación (`INT-AUTH`) son el **ítem #1 de recorte** si el tiempo aprieta.

2. **Convenciones de Ramas y Git**:
   - Cada tarjeta se trabaja en su propia rama saliendo de `develop`.
   - Formato de rama: `feature/<tipo>-<modulo>-<slug>`.
   - Commits con Conventional Commits (ej. `feat(tanda): crear tanda con codigo de invitacion AP-01`).
   - Todo cambio entra por Pull Request con *Squash and Merge* y requiere aprobación de otro integrante (Brandon, Karen o Lizeth).

---

## 1. `[INT-AUTH] Enviar correo de confirmación de registro (Resend/SendGrid)`

* **Sprint / Fecha**: Sprint 6 (13 de noviembre).
* **Tipo / Módulo**: `INT-AUTH` (Integración externa en Autenticación).
* **Prioridad**: **Baja** (Primer candidato a recorte si falta tiempo).
* **Rama Git sugerida**: `feature/int-auth-enviar-correo-de`

### ¿Qué se debe hacer técnicamente?
1. **Definir el Puerto en Dominio (`src/auth/domain/ports/out/mail.port.ts`)**:
   - Crear una interfaz TypeScript pura (agnóstica de NestJS):
     ```typescript
     export interface MailPort {
       sendWelcomeEmail(to: string, name: string): Promise<void>;
     }
     export const MAIL_PORT = Symbol('MAIL_PORT');
     ```
2. **Implementar el Adaptador en Infraestructura (`src/auth/infrastructure/adapters/out/mail/resend-mail.adapter.ts`)**:
   - Consumir el SDK de Resend o SendGrid utilizando credenciales configuradas en las variables de entorno (`RESEND_API_KEY`).
3. **Desacoplamiento mediante Eventos Internos**:
   - En [`AuthService.register()`](./Tandea-Back-End/src/auth/application/services/auth.service.ts), al crear un usuario con éxito, emitir el evento `usuario.registrado` mediante `EventEmitter2` de `@nestjs/event-emitter`.
   - Crear un listener (`AuthEventsListener`) con `@OnEvent('usuario.registrado')` que invoque a `MailPort`.
4. **Resiliencia ante fallos (Regla crítica)**:
   - Capturar cualquier excepción de red o error de API con `try/catch` y registrar en el log del sistema (`Logger.warn / Logger.error`).
   - **El envío de correo nunca debe romper ni revertir la respuesta HTTP 201 del registro de usuario**.

---

## 2. `[BE-TANDA] Crear tanda y generar código único de invitación (AP-01)`

* **Sprint / Fecha**: Sprint 2 (15 de octubre).
* **Tipo / Módulo**: `BE-TANDA`.
* **Historia de Usuario**: **AP-01**.
* **Prioridad**: **Alta** (Imprescindible para el MVP).
* **Rama Git sugerida**: `feature/be-tanda-crear-tanda-y`

### ¿Qué se debe hacer técnicamente?
1. **Estructura Hexagonal del Módulo `tandas` (`src/tandas/`)**:
   - **`domain/`**:
     - Entidad `Tanda` con sus invariantes y estados (`PENDIENTE`, `ACTIVA`, `FINALIZADA`, etc.).
     - Puertos de entrada: `create-tanda-use-case.port.ts` (`CREATE_TANDA_USE_CASE_PORT`).
     - Puertos de salida: `tanda-repository.port.ts` (`TANDA_REPOSITORY_PORT`).
     - Errores de dominio: `tanda.errors.ts` (ej. `InvalidTandaConfigError`).
   - **`application/`**:
     - `dtos/`: Schemas de validación en Zod (`zTandaCreate`, `zTandaResponse`).
     - `services/`: `TandaService` orquestando la creación.
   - **`infrastructure/`**:
     - `adapters/in/http/`: `TandaController` exponiendo `POST /api/v1/tandas` con `JwtAuthGuard`.
     - `adapters/out/database/`: `DrizzleTandaRepository` interactuando con [`tandaTable`](./Tandea-Back-End/src/database/tandea.schema.ts).
2. **Generador de Código Único de Invitación (`inviteCode`)**:
   - Generar un código alfanumérico legible de 6 a 8 caracteres (ej. `TND-7A8B`).
   - Validar unicidad contra la base de datos (la columna `invite_code` tiene restricción `@unique`).
3. **Reglas de Negocio al Crear**:
   - Asignar al usuario autenticado (`@CurrentUser().idUser`) como `idAdmin` (organizador).
   - Estado inicial siempre en `'PENDIENTE'`.
   - Validar parámetros mínimos: `numParticipants >= 2`, `contributionAmount > 0`, `graceDays >= 0`, `numRounds >= 1`.
   - Si `hasDeadNumber = true`, habilitar la reserva de número muerto para respaldo de impagos.

---

## 3. `[BE-TANDA] Asignar números automáticamente o por elección del participante`

* **Sprint / Fecha**: Sprint 2 (15 de octubre).
* **Tipo / Módulo**: `BE-TANDA`.
* **Prioridad**: **Alta**.
* **Rama Git sugerida**: `feature/be-tanda-asignar-numeros-automaticamente`

### ¿Qué se debe hacer técnicamente?
1. **Operación sobre [`numberTable`](./Tandea-Back-End/src/database/tandea.schema.ts)**:
   - Los números representan la posición de cobro de cada participante dentro de cada ronda/vuelta (`roundNumber`).
   - Cada fila almacena: `idTanda`, `roundNumber`, `numberValue`, `idUser`, `isDeadNumber`, `status` (`'PENDIENTE'`).
   - Restricción única en BD: `[idTanda, roundNumber, numberValue]` (un turno no puede asignarse dos veces en la misma ronda).
2. **Modalidad 1 — Elección Manual por el Participante**:
   - El participante elige un número `X` (`1 <= X <= numParticipants`).
   - Verificar que el número esté libre en la tanda. Si ya está tomado, retornar error de dominio `NumeroYaOcupadoError` (HTTP 409 Conflict).
3. **Modalidad 2 — Asignación Automática**:
   - Si el participante no envía un número específico (o la tanda es modo sorteo):
     - Consultar los números actualmente ocupados en la tanda.
     - Seleccionar el primer número disponible en el rango `1..numParticipants` (o realizar sorteo aleatorio).
     - Asignar el número al `idUser`.
4. **Manejo del Número Muerto (`hasDeadNumber = true`)**:
   - Reservar un turno especial con `idUser: null` y `isDeadNumber: true`.
   - Este turno queda bloqueado de cobro regular y se utiliza posteriormente en el Sprint 6 para cubrir pagos faltantes tras agotar los días de gracia (`AP-10`).

---

## 4. `[BE-TANDA] Unirse a una tanda con código único (AP-02)`

* **Sprint / Fecha**: Sprint 2 (15 de octubre).
* **Tipo / Módulo**: `BE-TANDA`.
* **Historia de Usuario**: **AP-02** (vinculada con *Validar que un número elegido no pueda tomarse dos veces*).
* **Prioridad**: **Alta**.
* **Rama Git sugerida**: `feature/be-tanda-unirse-a-una`

### ¿Qué se debe hacer técnicamente?
1. **Endpoint HTTP**:
   - `POST /api/v1/tandas/unirse` (o `/api/v1/tandas/join`).
   - Headers: `Authorization: Bearer <jwt_token>`.
   - Body DTO (validado con Zod):
     ```json
     {
       "inviteCode": "TND-7A8B",
       "selectedNumber": 3
     }
     ```
2. **Validaciones del Caso de Uso (`JoinTandaUseCase`)**:
   - **Buscar tanda**: Buscar en `tandaTable` por `inviteCode`. Si no existe o `active = false`, lanzar `TandaNotFoundError` (404).
   - **Estado de la tanda**: Solo admitir participantes si la tanda está en `status = 'PENDIENTE'` (si ya está `ACTIVA`, `FINALIZADA` o `CANCELADA`, retornar 422).
   - **Cupo disponible**: Contar los registros actuales en `numberTable` para esa tanda. Si ya alcanzó `numParticipants`, lanzar `TandaLlenaError` (422).
   - **Participante no repetido**: Validar que el usuario no esté ya registrado en la tanda (salvo que la configuración permita múltiples números por usuario).
   - **Asignación del turno**: Ejecutar la lógica de asignación (manual o automática).
3. **Transición de Estado de la Tanda**:
   - Si con esta unión se completa el cupo (`numParticipants`), evaluar la lógica de negocio: notificar al organizador para iniciar la tanda o cambiar automáticamente su estado a `'ACTIVA'`.

---

## 📋 Resumen Comparativo de las 4 Tarjetas

| Tarjeta | Tipo | Sprint | Prioridad | ¿Se puede recortar? | Componente Principal |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **`[INT-AUTH] Correo confirmación`** | INT | Sprint 6 (13 nov) | **Baja** | **Sí (Opción #1)** | Evento `usuario.registrado` + Resend/SendGrid adapter |
| **`[BE-TANDA] Crear tanda (AP-01)`** | BE | Sprint 2 (15 oct) | **Alta** | **No (Crítica)** | `POST /api/v1/tandas` + generación de `inviteCode` |
| **`[BE-TANDA] Asignar números`** | BE | Sprint 2 (15 oct) | **Alta** | **No (Crítica)** | Lógica de selección manual vs sorteo en `numberTable` |
| **`[BE-TANDA] Unirse a tanda (AP-02)`** | BE | Sprint 2 (15 oct) | **Alta** | **No (Crítica)** | `POST /api/v1/tandas/unirse` + validación de cupo y unicidad |

---

## ✅ Checklist de Definición de Hecho (DoD)

Antes de mover cualquiera de estas tarjetas a **"Hecho"** en el tablero:

- [ ] Cumple el criterio de aceptación de la historia (AP-01 / AP-02).
- [ ] Compila y pasa el linter (`npm run lint` con Oxlint).
- [ ] Pasan las pruebas unitarias e integración (`npm run test`).
- [ ] Pull Request abierto hacia la rama `develop`.
- [ ] Aprobado por al menos un integrante del equipo.
- [ ] PR vinculado a la tarjeta correspondiente en Trello.
