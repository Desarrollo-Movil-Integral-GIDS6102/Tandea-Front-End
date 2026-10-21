# 📝 Ficha de Diseño: Nube y Seguridad

**Proyecto:** Tandea — Plataforma de Gestión de Ahorro Rotativo (Tandas)  
**Tecnología / Lenguaje de la App Móvil:** Flutter (Dart SDK ^3.13)  
**Tecnología del Servidor / Backend:** NestJS + Fastify (TypeScript), Drizzle ORM y PostgreSQL  

---

## Bloque 1: El Componente en la Nube

* **Proveedor elegido:**  
  **Railway** (PaaS para despliegue de contenedor NestJS y base de datos relacional PostgreSQL gestionada) en integración con **Google Firebase** (Firebase Cloud Messaging para notificaciones push y Firebase Storage para archivos).

* **¿Para qué se usará la nube?**
  * **[X] Autenticación:** Registro y login de usuarios gestionado en el backend con contraseñas cifradas vía hash con salt (`bcrypt`) y emisión de credenciales de sesión en tokens JWT con firma criptográfica.
  * **[X] Base de datos:** Base de datos relacional PostgreSQL alojada en Railway para la persistencia transaccional de usuarios, tandas, turnos asignados, estados de pago y auditoría.
  * **[X] Almacenamiento de archivos:** Firebase Storage (plan Spark sin costo) para el almacenamiento en la nube de comprobantes de pago transferidos y fotografías de evidencia de entrega.
  * **[X] Funciones de servidor / Backend:** API REST modular (NestJS en Railway) para la ejecución de reglas de negocio críticas: validación de concurrencia al seleccionar turnos, generación de códigos únicos de invitación y cálculo del plan de cuotas.

---

## 🔒 Bloque 2: Las 3 Reglas de Seguridad

1. **En el teléfono del usuario (¿Cómo aseguran que nadie robe los datos guardados en la app?):**  
   * **Regla:** Ninguna contraseña ni dato sensible en texto plano se almacena en el dispositivo. La sesión del usuario se administra mediante un token JWT temporal almacenado de forma cifrada a través de la librería `flutter_secure_storage`, la cual delega la encriptación por hardware a **Android Keystore** en dispositivos Android y a **Apple Keychain** en iOS. Si la sesión caduca o el usuario cierra sesión, el almacenamiento seguro local se purga de inmediato.

2. **En el viaje de los datos (¿Cómo protegen la información cuando viaja del teléfono a la nube?):**  
   * **Regla:** Todo el intercambio de información entre la app móvil y el servidor se transmite estrictamente mediante el protocolo cifrado **HTTPS con TLS 1.3** a través del dominio seguro (`https://tandea-back-end-production.up.railway.app`). Cada petición que consulta o muta recursos protegidos viaja acompañada de la cabecera estándar de autorización `Authorization: Bearer <token_jwt>`.

3. **En la base de datos (¿Cómo evitan que un usuario vea o borre los datos de otro usuario?):**  
   * **Regla:** Aislamiento de acceso a nivel de aplicación mediante guardias (`JwtAuthGuard`) y filtros de dominio en NestJS. El backend extrae la identidad del usuario verificado a partir de la firma del JWT e implementa validaciones que impiden que un participante acceda o modifique tandas o comprobantes ajenos; únicamente el organizador (`idAdmin`) o el titular legítimo del turno tienen privilegios de lectura y confirmación sobre sus datos correspondientes.

---

## 🛡️ Bloque 3: Protección del Código (Buenas Prácticas)

* **¿Cómo van a ocultar las credenciales (API Keys) para que no se suban por error a su repositorio público (ej. GitHub) y cualquiera pueda usarlas?**  
  * **Exclusión preventiva en `.gitignore`:** Los archivos reales con secretos locales (`.env`) en frontend y backend están agregados a los archivos `.gitignore` de sus respectivos repositorios para asegurar que Git jamás rastree ni suba credenciales sensibles.
  * **Plantilla pública desacoplada:** Únicamente se incluye en el control de versiones el archivo `.env.example`, el cual sirve de contrato técnico documentando las variables requeridas con valores ficticios.
  * **Inyección de variables en nube:** En el entorno de producción en Railway, las credenciales reales (`DATABASE_URL`, `JWT_SECRET`, llaves de API) se inyectan como variables de entorno privadas encriptadas desde el panel de Railway. En Flutter, los endpoints se compilan de forma segura mediante directivas `--dart-define`.
