# Backend local-first de Horneaditos

Este paquete conserva las recetas en SQLite y sincroniza con Supabase cuando hay
conectividad. El `sincronizado` local vale `0` mientras un cambio está pendiente
y solo pasa a `1` después de que Supabase confirma el `upsert`.

## Configuración

1. Ejecuta `backend/supabase_schema.sql` en el SQL Editor de tu proyecto Supabase.
2. En `frontend/horneaditos_app`, ejecuta `flutter pub get`.
3. Inicializa el backend una vez, con las credenciales de tu proyecto en variables
   de compilación (no las guardes en el repositorio):

```powershell
Set-Location frontend\horneaditos_app
$env:SUPABASE_PUBLISHABLE_KEY = 'REEMPLAZA_LOCALMENTE'
flutter run --dart-define=SUPABASE_PUBLISHABLE_KEY=$env:SUPABASE_PUBLISHABLE_KEY
```

```dart
final backend = await HorneaditosBackend.initialize(
  supabaseUrl: const String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://cktmjeooqpcuygauuqua.supabase.co',
  ),
  supabasePublishableKey: const String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  ),
);
```

La app debe tener una sesión autenticada de Supabase antes de sincronizar o
restaurar recetas. Al iniciar sesión en un dispositivo nuevo, llama
`backend.restoreRecipesForCurrentUser()`. Ese método descarga las recetas del
usuario y las integra con SQLite sin reemplazar cambios locales pendientes.
El servicio escucha cambios de conectividad y vuelve a intentar la cola local.
El esquema remoto esperado es `public.users` y `public.foro`, con los nombres de
columnas del SQL. Antes de subir recetas, el backend crea o actualiza la fila del
usuario en `public.users`, requerida por la clave foránea de `foro`. El usuario
Supabase debe tener un correo, porque `public.users.correo` es obligatorio.
Usa únicamente la clave pública `anon`/publishable; nunca la `service_role`.
**Advertencia:** las políticas RLS del script compartido permiten cualquier
operación sobre ambas tablas (`USING (true)` y `WITH CHECK (true)`), incluyendo
solicitudes anónimas si los permisos de tabla también las autorizan. Esto no
aísla los datos por usuario y no debería usarse así en producción.
La pantalla de acceso actual sigue siendo una maqueta y aún no inicia sesión con
Supabase Auth; la sincronización y restauración requieren una sesión real. El
campo `imagen` conserva una ruta local y todavía no sube archivos a Supabase
Storage, por lo que esa imagen no se restaurará en otros dispositivos.

## API principal

```dart
final recipe = Recipe.create(
  category: 'CALIENTES',
  name: 'Pastel de chocolate',
  duration: '45 minutos',
  ingredients: 'Harina, cacao, azúcar...',
  preparation: 'Mezclar y hornear...',
);

final saved = await backend.recipes.saveRecipe(recipe);
final localRecipes = await backend.recipes.getRecipes();
```

`saveRecipe` persiste primero en SQLite, retorna el registro local y sube la
operación en segundo plano. Si el dispositivo está desconectado o Supabase no
está disponible, queda en la cola local con `sincronizado = 0`. `getRecipes`
permite consultar el estado actualizado. `Recipe.create` genera el identificador
UUID. Las recetas Supabase pertenecen al usuario autenticado y las políticas RLS
del SQL compartido actualmente no limitan lectura ni escritura por propietario.

SQLite usa `sqflite`, por lo que este backend está preparado para Android, iOS y
macOS; web, Windows y Linux requieren un adaptador de base de datos distinto.
Al actualizar una base local anterior, las recetas cuya categoría ya no existe
se conservan y pasan a `CALIENTES`; revisa esa categoría después de la migración.
