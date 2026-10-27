# Backend local-first de Horneaditos

Este paquete conserva las recetas en SQLite y sincroniza con Supabase cuando hay
conectividad. El `sincronizado` local vale `0` mientras un cambio está pendiente
y solo pasa a `1` después de que Supabase confirma el `upsert`.

## Configuración

1. Ejecuta `backend/supabase_schema.sql` en el SQL Editor de tu proyecto Supabase.
2. Ejecuta `backend/auth_policies.sql` después del script de esquema. Este quita
   las políticas abiertas y permite crear el propio perfil solo con `rol=user`,
   impidiendo que un usuario se promueva a admin desde la app.
3. En `frontend/horneaditos_app`, ejecuta `flutter pub get`.
4. Inicializa el backend una vez, con las credenciales de tu proyecto en variables
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

El registro usa Supabase Auth con correo, contraseña, nombre y apellido. Auth
guarda la contraseña de forma segura; no se copia a SQLite. La tabla `users`
recibe el id de Auth y sus metadatos, mientras rol y estado usan los valores
predeterminados `user` y `activo`. Con la confirmación de correo desactivada, el
registro inicia sesión inmediatamente. La sesión/JWT persistida por Supabase se
restaura desde `currentSession`, por lo que un usuario con sesión guardada puede
abrir la app sin conexión; el primer login o registro sí requiere conexión.
Cerrar sesión elimina la sesión local.

Para dar de alta al administrador inicial sin poner la contraseña en el código:
regístralo una vez desde la app con el correo y nombre deseados (la contraseña
se envía directamente a Supabase Auth), luego promueve su perfil en el SQL Editor:

```sql
UPDATE public.users
SET rol = 'admin'
WHERE correo = 'manuelgalindo009@gmail.com';
```

Comprueba que se actualizó exactamente una fila. No pongas la contraseña en SQL,
archivos del repositorio ni variables persistentes. La fila debe existir primero
por el registro en la app. Cierra y vuelve a iniciar sesión para refrescar el rol
guardado en SQLite; la sesión actual no necesita invalidarse en Supabase.

Al iniciar sesión en un dispositivo nuevo, la app restaura el foro público y lo
integra con SQLite sin reemplazar cambios locales pendientes. El perfil consulta
solo las recetas del usuario autenticado. El servicio escucha cambios de
conectividad y vuelve a intentar altas, ediciones y eliminaciones pendientes.
El esquema remoto esperado es `public.users` y `public.foro`, con los nombres de
columnas del SQL. Antes de subir recetas, el backend crea o actualiza la fila del
usuario en `public.users`, requerida por la clave foránea de `foro`. El usuario
Supabase debe tener un correo, porque `public.users.correo` es obligatorio.
Usa únicamente la clave pública `anon`/publishable; nunca la `service_role`.
El script inicial que compartiste abría RLS en ambas tablas; por eso es necesario
aplicar `auth_policies.sql` antes de usar cuentas reales. El acceso a recetas de
foro queda público de lectura, y las escrituras exigen autenticación y propiedad.
El formulario guarda en `imagen` una URL pública (si se proporciona), no una ruta
local ni un archivo cargado a Supabase Storage.

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
final forumRecipes = await backend.recipes.getForumRecipes();
final myRecipes = await backend.recipes.getMyRecipes();
final profile = await backend.recipes.getCurrentProfile();
await backend.recipes.deleteRecipe(saved);
```

`saveRecipe` persiste primero en SQLite, retorna el registro local y sube la
operación en segundo plano. Si el dispositivo está desconectado o Supabase no
está disponible, queda en la cola local con `sincronizado = 0`. `getRecipes`
permite consultar el estado actualizado. `Recipe.create` genera el identificador
UUID. Las recetas Supabase pertenecen al usuario autenticado y las políticas RLS
de `auth_policies.sql` permiten lectura pública del foro y escritura solo al
propietario autenticado.

`getForumRecipes` actualiza el cache público cuando hay conexión; sin conexión
devuelve el foro disponible localmente. `getMyRecipes` filtra siempre por el
usuario actual. Las eliminaciones se guardan en una cola SQLite independiente y
se retiran de Supabase al recuperar conectividad. El perfil ofrece el resumen de
la cuenta y `AuthService.updatePassword` cambia la contraseña mediante Supabase
Auth; las contraseñas nunca se almacenan en SQLite. El formulario acepta una URL
para la imagen; la subida de archivos requiere configurar un bucket de Storage.

SQLite usa `sqflite`, por lo que este backend está preparado para Android, iOS y
macOS; web, Windows y Linux requieren un adaptador de base de datos distinto.
Al actualizar una base local anterior, las recetas cuya categoría ya no existe
se conservan y pasan a `CALIENTES`; revisa esa categoría después de la migración.
