import 'package:flutter/material.dart';
import 'package:horneaditos_backend/horneaditos_backend.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _cream = Color(0xFFFFF8EF);
const _paper = Color(0xFFFFFEFA);
const _butter = Color(0xFFD9A93D);
const _cocoa = Color(0xFF4B2D23);
const _caramel = Color(0xFFB05D37);
const _muted = Color(0xFF8E7D70);
const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://cktmjeooqpcuygauuqua.supabase.co',
);
const _supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

final supabase = Supabase.instance.client;
late final HorneaditosBackend backend;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_supabasePublishableKey.isEmpty) {
    throw StateError(
      'Falta SUPABASE_PUBLISHABLE_KEY. Inicia Flutter con '
      '--dart-define=SUPABASE_PUBLISHABLE_KEY=<tu-clave-anon>.',
    );
  }
  backend = await HorneaditosBackend.initialize(
    supabaseUrl: _supabaseUrl,
    supabasePublishableKey: _supabasePublishableKey,
  );
  runApp(const HorneaditosApp());
}

class HorneaditosApp extends StatelessWidget {
  const HorneaditosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Horneaditos',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _caramel,
          primary: _cocoa,
          secondary: _butter,
          surface: _paper,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: _cocoa,
            fontSize: 30,
            fontFamily: 'serif',
            fontWeight: FontWeight.w400,
            height: 1.1,
          ),
          titleLarge: TextStyle(
            color: _cocoa,
            fontSize: 21,
            fontFamily: 'serif',
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(color: _muted, fontSize: 15, height: 1.45),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _paper,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE9DFD0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE9DFD0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _caramel, width: 1.5),
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _enterKitchen() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandMark(),
                    const SizedBox(height: 42),
                    const _Eyebrow('TU RECETARIO, SIEMPRE CONTIGO'),
                    const SizedBox(height: 9),
                    Text(
                      'Qué bueno verte de nuevo.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Entra y vuelve a esos pequeños momentos que saben a hogar.',
                    ),
                    const SizedBox(height: 30),
                    const _FieldLabel('Correo electrónico'),
                    TextFormField(
                      key: const ValueKey('login-email'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'hola@ejemplo.com',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                      validator: (value) {
                        if (value == null || !value.contains('@')) {
                          return 'Escribe un correo válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    const _FieldLabel('Contraseña'),
                    TextFormField(
                      key: const ValueKey('login-password'),
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _enterKitchen(),
                      decoration: const InputDecoration(
                        hintText: 'Tu contraseña',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Usa al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PrimaryButton(label: 'Ingresar', onPressed: _enterKitchen),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('¿Aún no tienes cuenta?'),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RegisterPage(),
                            ),
                          ),
                          child: const Text('Registrarme'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  void _createAccount() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomePage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Volver',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _BrandMark(compact: true),
                    const SizedBox(height: 34),
                    const _Eyebrow('UN LUGAR EN NUESTRA MESA'),
                    const SizedBox(height: 9),
                    Text(
                      'Algo dulce empieza aquí.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Crea tu cuenta para guardar y compartir tus recetas hechas con cariño.',
                    ),
                    const SizedBox(height: 28),
                    const _FieldLabel('¿Cómo te llamas?'),
                    TextFormField(
                      key: const ValueKey('register-name'),
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Tu nombre',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Cuéntanos tu nombre'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Correo electrónico'),
                    TextFormField(
                      key: const ValueKey('register-email'),
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'hola@ejemplo.com',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'Escribe un correo válido'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Crea una contraseña'),
                    TextFormField(
                      key: const ValueKey('register-password'),
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Mínimo 6 caracteres',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? 'Usa al menos 6 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 26),
                    _PrimaryButton(
                      label: 'Registrarme',
                      onPressed: _createAccount,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Ya tengo una cuenta · Ingresar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _categories = const ['Todo', 'Pasteles', 'Galletas', 'Pan dulce'];
  String _selectedCategory = 'Todo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
          children: [
            Row(
              children: [
                const _BrandMark(compact: true),
                const Spacer(),
                IconButton.filledTonal(
                  tooltip: 'Mi perfil',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfilePage(),
                    ),
                  ),
                  icon: const Icon(Icons.person_outline_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF0E6D8),
                    foregroundColor: _cocoa,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const _Eyebrow('UN LUGAR EN NUESTRA MESA'),
            const SizedBox(height: 9),
            Text(
              'Hoy se hornea.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            const Text('Ideas dulces para compartir.'),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AddRecipePage(),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Agregar receta'),
                style: FilledButton.styleFrom(
                  backgroundColor: _cocoa,
                  foregroundColor: _paper,
                ),
              ),
            ),
            const SizedBox(height: 22),
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar una receta',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  tooltip: 'Filtros',
                  onPressed: () {},
                  icon: const Icon(Icons.tune_rounded),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('Categorías', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _butter,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LA RECETA DEL DÍA',
                          style: TextStyle(
                            color: _cocoa,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Galletas de chocolate',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        const Text('Crujientes por fuera, tiernas por dentro.'),
                        const SizedBox(height: 14),
                        const Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: _cocoa,
                            ),
                            SizedBox(width: 5),
                            Text('45 min', style: TextStyle(color: _cocoa)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 76,
                    height: 92,
                    child: Icon(Icons.cake_rounded, size: 68, color: _caramel),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              '¿Qué se te antoja?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final selected = category == _selectedCategory;
                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = category),
                    backgroundColor: _paper,
                    selectedColor: _cocoa,
                    labelStyle: TextStyle(
                      color: selected ? _paper : _cocoa,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: selected ? _cocoa : const Color(0xFFE9DFD0),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Para hornear hoy',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(onPressed: () {}, child: const Text('Ver todas')),
              ],
            ),
            const SizedBox(height: 8),
            const _RecipeRow(
              title: 'Panqué de limón',
              subtitle: 'Suave, aromático y recién horneado',
              time: '25 min',
              icon: Icons.cookie_rounded,
              color: Color(0xFFF3DFC9),
            ),
            const SizedBox(height: 12),
            const _RecipeRow(
              title: 'Pastel de vainilla',
              subtitle: 'Un clásico para compartir en la mesa',
              time: '1 h 10 min',
              icon: Icons.breakfast_dining_rounded,
              color: Color(0xFFE8E0C8),
            ),
          ],
        ),
      ),
    );
  }
}

class AddRecipePage extends StatefulWidget {
  const AddRecipePage({
    super.key,
    this.initialCategory,
    this.initialName = '',
    this.isEditing = false,
  });

  final String? initialCategory;
  final String initialName;
  final bool isEditing;

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  static const _categories = ['PASTEL', 'GALLETA', 'PAN', 'POSTRE'];

  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.initialName);
  String? _category;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _publish() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta maqueta no guarda recetas todavía.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
            children: [
              const _BrandMark(compact: true),
              const SizedBox(height: 30),
              const _Eyebrow('AGREGAR RECETA'),
              const SizedBox(height: 9),
              Text(
                'Comparte tu toque especial.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'De tu cocina a nuestro recetario. Cuéntanos cómo preparas esa receta que siempre triunfa.',
              ),
              const SizedBox(height: 24),
              const _FieldLabel('Categoría'),
              DropdownButtonFormField<String>(
                key: const ValueKey('recipe-category'),
                initialValue: _category,
                isExpanded: true,
                hint: const Text('Selecciona una categoría'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.expand_more_rounded),
                ),
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _category = value),
                validator: (value) =>
                    value == null ? 'Elige una categoría' : null,
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Nombre'),
              TextFormField(
                key: const ValueKey('recipe-name'),
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Ej. Galletas de chocolate',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Escribe el nombre de la receta'
                    : null,
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Duración'),
              TextFormField(
                key: const ValueKey('recipe-duration'),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Ej. 25 minutos',
                  prefixIcon: Icon(Icons.schedule_rounded),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Indica cuánto tiempo toma'
                    : null,
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Ingredientes'),
              TextFormField(
                key: const ValueKey('recipe-ingredients'),
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Anota cada ingrediente y su cantidad.\nEj. 200 g de harina',
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Añade los ingredientes'
                    : null,
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Preparación'),
              TextFormField(
                key: const ValueKey('recipe-preparation'),
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  hintText: 'Describe los pasos de tu receta.',
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Describe cómo se prepara'
                    : null,
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Imagen'),
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'La carga de imágenes estará disponible más adelante.',
                    ),
                  ),
                ),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Subir una foto de tu receta'),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size.fromHeight(70),
                  foregroundColor: _muted,
                  backgroundColor: _paper,
                  side: const BorderSide(color: Color(0xFFE9DFD0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _PrimaryButton(
                label: widget.isEditing ? 'Guardar cambios' : 'Publicar',
                onPressed: _publish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar receta?'),
        content: const Text(
          'Esta acción es solo una vista de demostración. No se eliminarán datos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
          children: [
            const _BrandMark(compact: true),
            const SizedBox(height: 30),
            const _Eyebrow('PERFIL'),
            const SizedBox(height: 9),
            Text(
              'Tu rincón del recetario.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Cada receta cuenta una historia. Aquí están las que has compartido con nuestra comunidad.',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: const BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: Color(0xFFE9DFD0)),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nombre', style: TextStyle(color: _muted)),
                        SizedBox(height: 5),
                        Text(
                          'Lucía Martín',
                          style: TextStyle(
                            color: _cocoa,
                            fontFamily: 'serif',
                            fontSize: 23,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Número de recetas publicadas',
                        style: TextStyle(color: _muted),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '1',
                        style: TextStyle(
                          color: _caramel,
                          fontFamily: 'serif',
                          fontSize: 25,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Recetas publicadas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEFE6D9)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Categoría',
                          style: TextStyle(color: _muted),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Galletas',
                          style: TextStyle(
                            color: _cocoa,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text('Nombre', style: TextStyle(color: _muted)),
                        const SizedBox(height: 4),
                        Text(
                          'Galletas de chocolate',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: _caramel),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 4,
                          children: [
                            TextButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AddRecipePage(
                                    initialCategory: 'GALLETA',
                                    initialName: 'Galletas de chocolate',
                                    isEditing: true,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 17),
                              label: const Text('Editar'),
                            ),
                            TextButton.icon(
                              onPressed: () => _confirmDelete(context),
                              icon: const Icon(Icons.delete_outline, size: 17),
                              label: const Text('Eliminar'),
                              style: TextButton.styleFrom(
                                foregroundColor: _caramel,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 82,
                    height: 108,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1E4D2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.cookie_rounded,
                      size: 42,
                      color: _caramel,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Tu toque especial ya forma parte de nuestra mesa.'),
          ],
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _muted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 40 : 52,
          height: compact ? 40 : 52,
          decoration: BoxDecoration(
            color: _butter,
            borderRadius: BorderRadius.circular(compact ? 13 : 17),
          ),
          child: Icon(
            Icons.cake_rounded,
            color: _cocoa,
            size: compact ? 24 : 31,
          ),
        ),
        const SizedBox(width: 11),
        Text(
          'Horneaditos',
          style: TextStyle(
            color: _cocoa,
            fontSize: compact ? 20 : 25,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: _cocoa,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _cocoa,
          foregroundColor: _paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}

class _RecipeRow extends StatelessWidget {
  const _RecipeRow({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE6D9)),
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _caramel, size: 34),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _cocoa,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 5),
                Text(
                  time,
                  style: const TextStyle(
                    color: _caramel,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Guardar receta',
            onPressed: () {},
            icon: const Icon(Icons.bookmark_border_rounded),
            color: _cocoa,
          ),
        ],
      ),
    );
  }
}
