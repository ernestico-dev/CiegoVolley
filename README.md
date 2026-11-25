# CiegoVolley

App Flutter para gestionar clubes, equipos y torneos de voleibol.
Backend con **Supabase** (Postgres + Auth), estado con **Riverpod** y
navegación con **go_router**.

## Requisitos

- Flutter 3.47+ (Dart 3.13+)
- Un proyecto de Supabase

## Puesta en marcha

1. Instala dependencias:

   ```bash
   flutter pub get
   ```

2. Crea el proyecto en [supabase.com](https://supabase.com) y copia la URL y
   la *anon/publishable key* desde **Project Settings → API**.

3. Crea tu archivo de configuración local:

   ```bash
   cp dart_defines/example.json dart_defines/dev.json
   ```

   Edita `dart_defines/dev.json` con tus valores. Ese archivo está ignorado por
   git.

4. Aplica el esquema inicial en **SQL Editor** (o con la CLI de Supabase):

   ```bash
   supabase db push
   # o pega supabase/migrations/20261108000000_init.sql en el SQL Editor
   ```

5. Ejecuta la app:

   ```bash
   flutter run -d chrome --dart-define-from-file=dart_defines/dev.json
   flutter run -d <dispositivo> --dart-define-from-file=dart_defines/dev.json
   ```

Si olvidas el `--dart-define-from-file`, la app arranca en una pantalla de
ayuda con las instrucciones en lugar del login.

## Estructura

```
lib/
├── main.dart                  # arranque: locale, Supabase, ProviderScope
├── app.dart                   # MaterialApp.router + tema + locale
├── core/
│   ├── config/app_env.dart    # variables de entorno de compilación
│   ├── router/                # rutas y guardas de sesión
│   ├── supabase/              # init del cliente + providers de sesión
│   ├── theme/                 # Material 3 y control de tema
│   ├── utils/                 # validadores y mensajes de error
│   └── widgets/               # widgets compartidos
└── features/
    ├── auth/                  # repositorio, controlador y pantalla de login
    ├── home/                  # resumen y accesos rápidos
    ├── shell/                 # NavigationBar de las pestañas
    ├── teams/                 # equipos (modelo, repositorio, lista, alta)
    ├── tournaments/           # torneos (placeholder)
    └── profile/               # cuenta, tema y cerrar sesión
```

Cada feature sigue el mismo patrón: `domain/` (modelos), `data/`
(repositorio + providers) y `presentation/` (pantallas y controladores).

## Decisiones técnicas

- **Rutas protegidas** en un único `redirect` de go_router: sin sesión solo
  `/login` es accesible.
- **Sesión síncrona**: `sessionProvider` arranca con `currentSession` y escucha
  `onAuthStateChange`, así no hay parpadeo al abrir la app.
- **RLS desde el primer día**: las tablas solo permiten leer a usuarios
  autenticados y escribir al dueño del registro.
- **Sin claves en el código**: todo entra por `--dart-define`.

## Siguientes pasos sugeridos

- Persistir el tema con `shared_preferences`.
- Añadir `players` y `team_members` al esquema.
- Pantalla de detalle de equipo y gestión de plantilla.
- Generación de calendario y actas de torneos.
- Tests de widgets por feature.

## Licencia

**Todos los derechos reservados.** Este repositorio es público únicamente para
consulta y evaluación: no se concede permiso para copiar, modificar,
distribuir ni usar el código, total o parcialmente, sin autorización previa por
escrito. Consulta el archivo [LICENSE](LICENSE) para los términos completos.

Para permisos de uso o licencias comerciales: ecpkiko2002@gmail.com.

## Comandos útiles

```bash
flutter analyze
flutter test
flutter build web --dart-define-from-file=dart_defines/dev.json
flutter build apk --release --dart-define-from-file=dart_defines/dev.json
```
