# Módulo de Pagos — Tandea (Documentación Técnica y Flujo AP-03)

El módulo de Pagos es el núcleo transaccional de Tandea. Permite a los participantes abonar sus cuotas mediante tres modalidades (Efectivo, Transferencia o Híbrido), respaldar el pago con comprobantes digitales y someter la transacción a doble confirmación (Organizador y Receptor) con validación OCR automatizada.

---

## 📐 Reglas de Negocio Financieras (Historia AP-03)

1. **Métodos de Pago Permitidos**:
   * **Efectivo (`efectivo`)**: El participante entrega el dinero en físico al organizador. `montoEfectivo == cuota`, `montoTransferencia == 0`. No requiere comprobante obligatorio.
   * **Transferencia (`transferencia`)**: El participante deposita vía SPEI/banco. `montoTransferencia == cuota`, `montoEfectivo == 0`. **Requiere comprobante digital obligatorio (`comprobanteUrl` / `fileUrl`)**.
   * **Híbrido (`hibrido`)**: El participante paga una parte en físico y el resto por transferencia.
2. **Invariante de Pago Híbrido**:
   $$\text{montoTransferencia} + \text{montoEfectivo} = \text{totalAmount} = \text{cuota de la tanda}$$
   Ambos parciales deben ser mayores estrictos a cero ($\text{transferencia} > 0 \land \text{efectivo} > 0$).
3. **Flujo de Estados del Pago**:
   * `PENDIENTE`: Registrado por el participante, esperando confirmación.
   * `CONFIRMADO`: Aprobado por el organizador tras verificar la recepción del dinero.
   * `RECHAZADO`: Declinado por el organizador por fondos no recibidos o comprobante inválido.

---

## 🏛️ Estructura en el Backend (`Tandea-Back-End`)

* **Tablas de Base de Datos** ([`src/database/tandea.schema.ts`](../Tandea-Back-End/src/database/tandea.schema.ts)):
  * **`paymentTable`**: Almacena `id_payment`, `id_number`, `transfer_amount`, `cash_amount`, `total_amount`, `confirmed_by_participant`, `confirmed_by_admin`, `status`.
  * **`evidenceTable`**: Almacena `id_evidence`, `id_payment`, `id_payout`, `file_url`.
* **Endpoint Principal**:
  * **`POST /api/v1/pagos`** (`multipart/form-data`, con JWT):
    * Campos: `idNumber`, `metodoPago` (`efectivo | transferencia | hibrido`), `transferAmount`, `cashAmount` y `file` (comprobante JPG, PNG o PDF de hasta 10 MB; obligatorio en transferencia e híbrido).
    * Respuestas:
      * `201 Created`: Pago registrado como `PENDIENTE`.
      * `400 Bad Request`: Archivo de tipo no permitido o contenido inválido.
      * `403 Forbidden`: El número no pertenece al usuario autenticado.
      * `404 Not Found`: El número o la tanda no existen.
      * `409 Conflict`: Ya existe un pago pendiente o confirmado para ese número.
      * `413 Payload Too Large`: El comprobante supera 10 MB.
      * `422 Unprocessable Entity`: Montos inválidos, suma distinta a la cuota o falta el comprobante.

---

## 📱 Estructura en el Frontend (`Tandea-Front-End`)

La pantalla, el flujo de datos, los campos enviados y los mensajes de error se describen en [`pagos.md`](./pagos.md).

* **Capa Domain**: `PagoEntity`, `MetodoPago`, `ComprobanteArchivo` y `PagoRepository.registrarPago(RegistrarPagoParams)`.
* **Capa Data**: `PagoRemoteDataSource` (Dio + `FormData`) y `PagoRepositoryImpl` (excepciones → `Failure`).
* **Capa Presentation**: `PagoProvider` (`EstadoCarga`, mensajes de error) y `RegistrarPagoScreen` con sus widgets en `presentation/widgets/`.
