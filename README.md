# Reiki App — proyecto Flutter

Flutter + Supabase, Riverpod, GoRouter, arquitectura en 3 capas
(presentación / dominio / datos), según las decisiones de las Fases 1-5.

Estado: **Fases 6 y 8 completadas; reservas por franjas, perfiles y panel admin en marcha.**

## Ejecutar

El andamiaje nativo ya está generado y Flutter está en el PATH. Para
arrancar en desarrollo hay un script que ya lleva las credenciales:

```powershell
.\run_dev.ps1            # elige dispositivo interactivamente
.\run_dev.ps1 chrome     # navegador
.\run_dev.ps1 Pixel_9_Pro  # emulador Android (requiere SVM en la BIOS)
```

`run_dev.ps1` está en `.gitignore` porque contiene las claves. A mano
sería:

```bash
flutter run \
  --dart-define=ENV=dev \
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_CLAVE
```

`SUPABASE_ANON_KEY` sigue aceptándose como alias, por compatibilidad con
los scripts antiguos.

## Estructura

```
lib/
  core/
    config/    → Env (variables de entorno vía --dart-define)
    theme/     → AppTheme, AppColors (paleta de la Fase 5)
    router/    → GoRouter + guard de sesión y rol
    errors/    → AppException (tipo de error único, Fase 2)
    utils/     → Validators (email, contraseña, teléfono)
  domain/
    models/    → Perfil, UserRole
  data/
    repositories/ → AuthRepository
    services/     → SupabaseService, NotificationService
  features/
    auth/              → login, registro, recuperación, splash, providers
    appointments/      → home cliente y agenda terapeuta
    booking/           → reservas por franjas compartidas
    therapists/        → ficha y disponibilidad de terapeutas
    profile/           → datos editables del usuario
    admin/              → gestión de perfiles y roles
  shared/
    widgets/           → navegación global, errores y menú de cuenta
  main.dart

test/  → validators_test, perfil_test, login_screen_test
```

## Fase 8 — Autenticación

Lo que quedó implementado:

- **Login** real contra Supabase Auth, con validación, estado de carga y
  traducción de los errores de Supabase al español.
- **Registro** de clientes (nombre, email, teléfono opcional,
  contraseña). El rol se fija siempre a `cliente` en el servidor de la
  lógica: nadie puede darse de alta como terapeuta desde la app.
- **Recuperación de contraseña** por email, con un mensaje genérico que
  no revela si la dirección está registrada.
- **`AuthRepository`** como único punto que habla con Supabase Auth y con
  la tabla de perfiles; la UI solo ve `AppException`.
- **Guard de rol en el router**: `cliente` → `/patient`, `terapeuta` →
  `/therapist` y `admin` → `/admin`, con navegación inferior adaptada a
  cada rol.
- **Cierre de sesión** desde el menú de cuenta de la `AppBar`.

Detalles del esquema real de Supabase que condicionaron el código:

- Las tablas están **en español**: `perfiles`, `citas`, `terapeutas`,
  `disponibilidad`. No existe `profiles`.
- Columnas de `perfiles`: `id`, `email`, `nombre`, `telefono`, `rol`,
  `expo_push_token`, `created_at`. El nombre `expo_push_token` viene de
  un diseño previo con Expo; esta app guardará ahí el token de FCM.
- El proyecto tiene la **confirmación por email activada**
  (`mailer_autoconfirm: false`), así que `signUp` nunca devuelve sesión y
  no se puede escribir en `perfiles` durante el registro. La fila se crea
  en el primer inicio de sesión, en `AuthRepository.fetchPerfil`, a
  partir de los metadatos guardados en `signUp`.
- Registrarse con un email que ya existe muestra "Revisa tu correo" en
  lugar de un error: es la protección de Supabase contra el sondeo de
  direcciones, no un fallo de la app.

## Pendiente

- **Fase 7 (Backend)**: ejecutar `supabase/003_rls_policies.sql` para
  activar RLS y las políticas por rol. Las migraciones `001` y `002`
  preparan franjas compartidas y la reserva atómica.
- **Fases 9-10**: la reserva por franjas ya está operativa; queda añadir
  una pantalla para que los terapeutas gestionen su disponibilidad sin SQL.
- **Cambio de contraseña**: el enlace del email lleva hoy a la "Site
  URL" de Supabase. Cuando haya deep links (Fase 11) hay que pasar
  `redirectTo` en `AuthRepository.sendPasswordReset` y añadir la
  pantalla de nueva contraseña.
- **Login con Google**: ya está habilitado en el proyecto de Supabase
  (`google: true`), pero la app todavía no lo ofrece.
- **Fase 11**: añadir `google-services.json` /
  `GoogleService-Info.plist` y activar `NotificationService`.
- **Toolchain de Android**: `JAVA_HOME` apunta a `...\jdk-21\bin` en vez
  de `...\jdk-21`, y eso hace fallar `flutter build apk`. El emulador
  además necesita SVM activado en la BIOS.
