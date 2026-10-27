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

bool _isValidEmail(String email) {
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
}

class HorneaditosApp extends StatelessWidget {
  const HorneaditosApp({super.key, this.authService, this.recipeRepository});

  final AuthService? authService;
  final RecipeRepository? recipeRepository;

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
      home: AuthGate(
        authService: authService ?? backend.auth,
        recipeRepository: recipeRepository ?? backend.recipes,
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({
    required this.authService,
    required this.recipeRepository,
    super.key,
  });

  final AuthService authService;
  final RecipeRepository recipeRepository;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<bool> _authStateChanges =
      widget.authService.authStateChanges;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _authStateChanges,
      initialData: widget.authService.hasSession,
      builder: (context, snapshot) {
        return snapshot.data == true
            ? HomePage(
                authService: widget.authService,
                recipeRepository: widget.recipeRepository,
              )
            : LoginPage(authService: widget.authService);
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({required this.authService, super.key});

  final AuthService authService;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _enterKitchen() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } on AuthException catch (error) {
      _showMessage(error.message);
    } on Exception {
      _showMessage(
        widget.authService.hasSession
            ? 'No se pudo validar la conexión. Se conservará la sesión local.'
            : 'No se pudo iniciar sesión. Revisa tu conexión e inténtalo de nuevo.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      _showMessage(
        'Escribe tu correo para enviarte el enlace de recuperación.',
      );
      return;
    }

    try {
      await widget.authService.resetPassword(email);
      _showMessage('Si el correo está registrado, recibirás un enlace.');
    } on AuthException catch (error) {
      _showMessage(error.message);
    } on Exception {
      _showMessage('No se pudo enviar el enlace. Comprueba tu conexión.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
                        if (!_isValidEmail(value ?? '')) {
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
                      onFieldSubmitted: (_) {
                        _enterKitchen();
                      },
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
                        onPressed: _isSubmitting ? null : _resetPassword,
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PrimaryButton(
                      label: _isSubmitting ? 'Ingresando…' : 'Ingresar',
                      onPressed: _isSubmitting ? null : _enterKitchen,
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('¿Aún no tienes cuenta?'),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  RegisterPage(authService: widget.authService),
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
  const RegisterPage({required this.authService, super.key});

  final AuthService authService;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final authenticated = await widget.authService.signUp(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      if (authenticated) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        _showMessage(
          'Cuenta creada. Inicia sesión cuando tu correo esté confirmado.',
        );
      }
    } on AuthException catch (error) {
      _showMessage(error.message);
    } on Exception {
      _showMessage(
        'No se pudo crear la cuenta. Revisa los datos y tu conexión.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
                    const _FieldLabel('Nombre'),
                    TextFormField(
                      key: const ValueKey('register-name'),
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Ej: Pedro',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Escribe tu nombre'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Apellido'),
                    TextFormField(
                      key: const ValueKey('register-last-name'),
                      controller: _lastNameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Ej: Perez',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Escribe tu apellido'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Correo electrónico'),
                    TextFormField(
                      key: const ValueKey('register-email'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'hola@ejemplo.com',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                      validator: (value) => !_isValidEmail(value ?? '')
                          ? 'Escribe un correo válido'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Crea una contraseña'),
                    TextFormField(
                      key: const ValueKey('register-password'),
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        _createAccount();
                      },
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
                      label: _isSubmitting ? 'Creando cuenta…' : 'Registrarme',
                      onPressed: _isSubmitting ? null : _createAccount,
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
  const HomePage({
    required this.authService,
    required this.recipeRepository,
    super.key,
  });

  final AuthService authService;
  final RecipeRepository recipeRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _categories = const ['Todo', 'FRIOS', 'FRITOS', 'CALIENTES'];
  final _searchController = TextEditingController();
  String _selectedCategory = 'Todo';
  late Future<List<Recipe>> _recipesFuture;

  @override
  void initState() {
    super.initState();
    _recipesFuture = widget.recipeRepository.getForumRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reloadRecipes() {
    final recipesFuture = widget.recipeRepository.getForumRecipes();
    setState(() {
      _recipesFuture = recipesFuture;
    });
  }

  Future<void> _addRecipe() async {
    final published = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            AddRecipePage(recipeRepository: widget.recipeRepository),
      ),
    );
    if (published == true && mounted) _reloadRecipes();
  }

  Future<void> _openProfile() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProfilePage(
          authService: widget.authService,
          recipeRepository: widget.recipeRepository,
        ),
      ),
    );
    if (changed == true && mounted) _reloadRecipes();
  }

  Future<void> _signOut() async {
    try {
      await widget.authService.signOut();
    } on AuthException catch (error) {
      _showSignOutError(error.message);
    } on Exception {
      _showSignOutError('No se pudo cerrar la sesión.');
    }
  }

  void _showSignOutError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

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
                  onPressed: _openProfile,
                  icon: const Icon(Icons.person_outline_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF0E6D8),
                    foregroundColor: _cocoa,
                  ),
                ),
                IconButton(
                  key: const ValueKey('sign-out'),
                  tooltip: 'Cerrar sesión',
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded),
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
                onPressed: _addRecipe,
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
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar una receta',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 28),
            Text('Categorías', style: Theme.of(context).textTheme.titleLarge),
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
                IconButton(
                  tooltip: 'Actualizar foro',
                  onPressed: _reloadRecipes,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Recipe>>(
              future: _recipesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Column(
                    children: [
                      const Text('No se pudo cargar el foro.'),
                      TextButton(
                        key: const ValueKey('home-feed-retry'),
                        onPressed: _reloadRecipes,
                        child: const Text('Intentar de nuevo'),
                      ),
                    ],
                  );
                }
                final query = _searchController.text.trim().toLowerCase();
                final recipes = snapshot.data!
                    .where(
                      (recipe) =>
                          (_selectedCategory == 'Todo' ||
                              recipe.category == _selectedCategory) &&
                          (query.isEmpty ||
                              recipe.name.toLowerCase().contains(query) ||
                              recipe.ingredients.toLowerCase().contains(query)),
                    )
                    .toList(growable: false);
                if (recipes.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 22),
                    child: Text('Aún no hay recetas que coincidan.'),
                  );
                }
                return Column(
                  children: [
                    for (var index = 0; index < recipes.length; index++) ...[
                      _RecipeRow(
                        recipe: recipes[index],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                RecipeDetailPage(recipe: recipes[index]),
                          ),
                        ),
                      ),
                      if (index != recipes.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AddRecipePage extends StatefulWidget {
  const AddRecipePage({required this.recipeRepository, super.key, this.recipe});

  final RecipeRepository recipeRepository;
  final Recipe? recipe;

  bool get isEditing => recipe != null;

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  static const _categories = ['FRIOS', 'FRITOS', 'CALIENTES'];

  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.recipe?.name);
  late final _durationController = TextEditingController(
    text: widget.recipe?.duration,
  );
  late final _ingredientsController = TextEditingController(
    text: widget.recipe?.ingredients,
  );
  late final _preparationController = TextEditingController(
    text: widget.recipe?.preparation,
  );
  late final _imageController = TextEditingController(
    text: widget.recipe?.imageUrl,
  );
  String? _category;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _category = widget.recipe?.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _ingredientsController.dispose();
    _preparationController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final previous = widget.recipe;
    final recipe = previous == null
        ? Recipe.create(
            category: _category!,
            name: _nameController.text.trim(),
            duration: _durationController.text.trim(),
            ingredients: _ingredientsController.text.trim(),
            preparation: _preparationController.text.trim(),
            imageUrl: _imageController.text.trim().isEmpty
                ? null
                : _imageController.text.trim(),
          )
        : previous.copyWith(
            category: _category!,
            name: _nameController.text.trim(),
            duration: _durationController.text.trim(),
            ingredients: _ingredientsController.text.trim(),
            preparation: _preparationController.text.trim(),
            imageUrl: _imageController.text.trim().isEmpty
                ? null
                : _imageController.text.trim(),
            clearImageUrl: _imageController.text.trim().isEmpty,
            updatedAt: DateTime.now().toUtc(),
            sincronizado: false,
          );
    try {
      await widget.recipeRepository.saveRecipe(recipe);
      if (mounted) Navigator.of(context).pop(true);
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar la receta: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
              _Eyebrow(widget.isEditing ? 'EDITAR RECETA' : 'AGREGAR RECETA'),
              const SizedBox(height: 9),
              Text(
                widget.isEditing
                    ? 'Actualiza tu receta.'
                    : 'Comparte tu toque especial.',
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
                controller: _durationController,
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
                controller: _ingredientsController,
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
                controller: _preparationController,
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
              const _FieldLabel('URL de imagen (opcional)'),
              TextFormField(
                key: const ValueKey('recipe-image'),
                controller: _imageController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  hintText: 'https://ejemplo.com/receta.jpg',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
              ),
              const SizedBox(height: 24),
              _PrimaryButton(
                label: _isSubmitting
                    ? 'Guardando…'
                    : widget.isEditing
                    ? 'Guardar cambios'
                    : 'Publicar',
                onPressed: _isSubmitting ? null : _publish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    required this.authService,
    required this.recipeRepository,
    super.key,
  });

  final AuthService authService;
  final RecipeRepository recipeRepository;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<(UserProfile, List<Recipe>)> _profileFuture = _loadProfile();
  bool _hasChanges = false;

  Future<(UserProfile, List<Recipe>)> _loadProfile() async {
    final profile = await widget.recipeRepository.getCurrentProfile();
    final recipes = await widget.recipeRepository.getMyRecipes();
    return (profile, recipes);
  }

  void _reload() {
    final profileFuture = _loadProfile();
    setState(() {
      _profileFuture = profileFuture;
    });
  }

  Future<void> _editRecipe(Recipe recipe) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddRecipePage(
          recipeRepository: widget.recipeRepository,
          recipe: recipe,
        ),
      ),
    );
    if (changed == true && mounted) {
      _hasChanges = true;
      _reload();
    }
  }

  Future<void> _deleteRecipe(Recipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar receta?'),
        content: Text('Se eliminará "${recipe.name}" de tus publicaciones.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.recipeRepository.deleteRecipe(recipe);
      if (!mounted) return;
      _hasChanges = true;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receta eliminada de tu perfil.')),
      );
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $error')));
      }
    }
  }

  Future<void> _changePassword() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _PasswordChangeDialog(
        updatePassword: widget.authService.updatePassword,
      ),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña se actualizó.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<(UserProfile, List<Recipe>)>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No se pudo cargar tu perfil.'),
                    TextButton(
                      onPressed: _reload,
                      child: const Text('Intentar de nuevo'),
                    ),
                  ],
                ),
              );
            }
            final (profile, recipes) = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
              children: [
                Row(
                  children: [
                    const _BrandMark(compact: true),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Volver',
                      onPressed: () => Navigator.of(context).pop(_hasChanges),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const _Eyebrow('PERFIL'),
                const SizedBox(height: 9),
                Text(
                  'Tu rincón del recetario.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Consulta tus datos y administra las recetas que has compartido.',
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: const BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(color: Color(0xFFE9DFD0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nombre',
                              style: TextStyle(color: _muted),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              profile.fullName,
                              style: const TextStyle(
                                color: _cocoa,
                                fontFamily: 'serif',
                                fontSize: 23,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              profile.email,
                              style: const TextStyle(color: _muted),
                            ),
                            Text('Rol: ${profile.role}'),
                            Text('Estado: ${profile.status}'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Número de recetas publicadas',
                            textAlign: TextAlign.end,
                            style: TextStyle(color: _muted),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${recipes.length}',
                            style: const TextStyle(
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const ValueKey('change-password'),
                    onPressed: _changePassword,
                    icon: const Icon(Icons.lock_reset_rounded),
                    label: const Text('Cambiar contraseña'),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Recetas publicadas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (recipes.isEmpty)
                  const Text('Todavía no has publicado recetas.')
                else
                  for (final recipe in recipes) ...[
                    _OwnedRecipeCard(
                      recipe: recipe,
                      onEdit: () => _editRecipe(recipe),
                      onDelete: () => _deleteRecipe(recipe),
                    ),
                    const SizedBox(height: 12),
                  ],
                const SizedBox(height: 8),
                const Text('Tu toque especial ya forma parte de nuestra mesa.'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OwnedRecipeCard extends StatelessWidget {
  const _OwnedRecipeCard({
    required this.recipe,
    required this.onEdit,
    required this.onDelete,
  });

  final Recipe recipe;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE6D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(recipe.category, style: const TextStyle(color: _muted)),
          const SizedBox(height: 5),
          Text(
            recipe.name,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: _caramel),
          ),
          const SizedBox(height: 5),
          Text('Duración: ${recipe.duration}'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                key: ValueKey('edit-${recipe.id}'),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Editar'),
              ),
              TextButton.icon(
                key: ValueKey('delete-${recipe.id}'),
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 17),
                label: const Text('Eliminar'),
                style: TextButton.styleFrom(foregroundColor: _caramel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PasswordChangeDialog extends StatefulWidget {
  const _PasswordChangeDialog({required this.updatePassword});

  final Future<void> Function(String password) updatePassword;

  @override
  State<_PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<_PasswordChangeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.updatePassword(_passwordController.text);
      if (mounted) Navigator.of(context).pop(true);
    } on Exception catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar contraseña'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const ValueKey('new-password'),
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nueva contraseña'),
              validator: (value) => value == null || value.length < 6
                  ? 'Usa al menos 6 caracteres'
                  : null,
            ),
            TextFormField(
              key: const ValueKey('confirm-password'),
              controller: _confirmationController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar contraseña',
              ),
              validator: (value) => value != _passwordController.text
                  ? 'Las contraseñas no coinciden'
                  : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(_submitting ? 'Guardando…' : 'Actualizar'),
        ),
      ],
    );
  }
}

class RecipeDetailPage extends StatelessWidget {
  const RecipeDetailPage({required this.recipe, super.key});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(recipe.name)),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          if (recipe.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                recipe.imageUrl!,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 140,
                  child: Icon(Icons.cake_rounded, size: 72, color: _caramel),
                ),
              ),
            ),
          const SizedBox(height: 18),
          _Eyebrow(recipe.category),
          const SizedBox(height: 8),
          Text(recipe.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Duración: ${recipe.duration}'),
          const SizedBox(height: 24),
          Text('Ingredientes', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(recipe.ingredients),
          const SizedBox(height: 24),
          Text('Preparación', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(recipe.preparation),
        ],
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
  final VoidCallback? onPressed;

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
  const _RecipeRow({required this.recipe, required this.onTap});

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _paper,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEFE6D9)),
          ),
          child: Row(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3DFC9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: recipe.imageUrl == null
                    ? const Icon(
                        Icons.cookie_rounded,
                        color: _caramel,
                        size: 34,
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          recipe.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.cookie_rounded,
                            color: _caramel,
                            size: 34,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        color: _cocoa,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${recipe.category} · ${recipe.ingredients}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      recipe.duration,
                      style: const TextStyle(
                        color: _caramel,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _cocoa),
            ],
          ),
        ),
      ),
    );
  }
}
