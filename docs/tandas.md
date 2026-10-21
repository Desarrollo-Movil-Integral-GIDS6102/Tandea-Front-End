# Módulo de Tandas — Especificación de Código de Invitación (AP-02)

## 1. Descripción Breve del Feature de Tandas
El módulo de **Tandas** en Tandea gestiona la creación, configuración y participación en grupos de ahorro rotativo comunitarios. Como parte de la historia de usuario **AP-02 (Unirse a una tanda activa)**, los usuarios participantes pueden consultar e incorporarse a una tanda existente introduciendo el código de invitación único generado por el organizador.

## 2. Formato del Código de Invitación
* **Formato estándar**: Prefijo `TND-` seguido de 6 caracteres alfanuméricos en mayúsculas (letras `A-Z` y dígitos `0-9`).
  * Ejemplo estándar (10 caracteres): `TND-7K9A2B`.
* **Compatibilidad hacia atrás**: Se admiten identificadores previos o variantes legadas de 8 caracteres alfanuméricos con o sin guion (ej. `TND-7K9A` o `ABC12345`), así como códigos intermedios de 9 caracteres.

## 3. Longitud Total y Rango Aceptado
* **Longitud mínima**: `8` caracteres (`UnirseTandaProvider.codigoMinLength`).
* **Longitud máxima**: `10` caracteres (`UnirseTandaProvider.codigoMaxLength`).
* **Rango aceptado**: Entre 8 y 10 caracteres inclusivos (`8 <= longitud <= 10`).

## 4. Expresión Regular (Regex) Utilizada
La validación sintáctica utiliza la siguiente expresión regular estricta:
```dart
RegExp(r'^[A-Z0-9\-]{8,10}$')
```
* `^`: Inicio de la cadena.
* `[A-Z0-9\-]`: Permite únicamente letras mayúsculas de la A a la Z, dígitos del 0 al 9 y el carácter de guion medio (`-`).
* `{8,10}`: Restringe la longitud de forma exacta al rango entre 8 y 10 caracteres.
* `$`: Fin de la cadena.

Cualquier carácter especial adicional (como `@`, `#`, `*`, espacios intermedios o minúsculas sin transformar) invalida la cadena.

## 5. Ubicación de la Validación
La validación se aplica en dos capas defensivas en la capa de presentación (`features/tandas/presentation`):

1. **Nivel de Entrada UI (`UnirseTandaScreen`)**:
   * **Ruta de archivo**: `lib/features/tandas/presentation/screens/unirse_tanda_screen.dart`
   * **Controles**:
     * `UpperCaseTextFormatter()`: Convierte automáticamente a mayúsculas cualquier texto ingresado.
     * `LengthLimitingTextInputFormatter(UnirseTandaProvider.codigoMaxLength)`: Trunca la entrada impidiendo escribir o pegar más de 10 caracteres.
     * `FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]'))`: Bloquea caracteres no permitidos a nivel de teclado.
     * `counterText`: Visualiza dinámicamente `${length}/10`.
     * `validator`: Verifica que el campo no esté vacío, que cumpla con el rango de longitud (8-10) y que coincida con `UnirseTandaProvider.regexCodigo`.

2. **Nivel de Gestión de Estado (`UnirseTandaProvider`)**:
   * **Ruta de archivo**: `lib/features/tandas/presentation/providers/unirse_tanda_provider.dart`
   * **Método**: `validarCodigoLocal()`
   * **Regla**: Antes de emitir cualquier petición HTTP (`consultarTanda()`), el proveedor valida el código. Si no cumple con el rango o patrón, establece `validationError` y previene el consumo innecesario de red.

## 6. Normalización Previa al Envío
Antes de validar o emitir peticiones al API (`GET /tandas/codigo/:inviteCode` o `POST /tandas/unirse`), se aplican las siguientes transformaciones deterministas:
1. `toUpperCase()`: Garantiza que cualquier letra esté en mayúscula.
2. `trim()`: Elimina espacios en blanco accidentales al inicio y al final de la cadena (por ejemplo, al pegar desde el portapapeles).

## 7. Verificación del Contrato de Backend
De acuerdo con la documentación técnica y los contratos del backend (`Tandea-Back-End`):
* El backend genera y almacena códigos alfanuméricos únicos en la columna `invite_code` de `tandaTable`.
* Los endpoints `GET /api/v1/tandas/codigo/:inviteCode` y `POST /api/v1/tandas/unirse` aceptan el código en formato texto. El ajuste en frontend garantiza la compatibilidad tanto con los códigos de 10 caracteres generados bajo la historia AP-02 (`TND-XXXXXX`) como con códigos heredados de 8 caracteres.
