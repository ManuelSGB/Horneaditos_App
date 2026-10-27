// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:horneaditos_backend/horneaditos_backend.dart';
import 'package:horneaditos_app/main.dart';

class FakeAuthService implements AuthService {
  FakeAuthService({bool initialSession = false}) : _hasSession = initialSession;

  final _authChanges = StreamController<bool>.broadcast(sync: true);
  bool _hasSession = false;
  String? signedInEmail;
  String? registeredFirstName;
  String? registeredLastName;
  String? registeredEmail;
  String? registeredPassword;
  String? updatedPassword;

  @override
  bool get hasSession => _hasSession;

  @override
  Stream<bool> get authStateChanges => _authChanges.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    signedInEmail = email;
    _hasSession = true;
    _authChanges.add(true);
  }

  @override
  Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    registeredFirstName = firstName;
    registeredLastName = lastName;
    registeredEmail = email;
    registeredPassword = password;
    _hasSession = true;
    _authChanges.add(true);
    return true;
  }

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<void> updatePassword(String password) async {
    updatedPassword = password;
  }

  @override
  Future<void> signOut() async {
    _hasSession = false;
    _authChanges.add(false);
  }

  Future<void> dispose() => _authChanges.close();
}

class FakeRecipeRepository implements RecipeRepository {
  FakeRecipeRepository({List<Recipe>? recipes})
    : recipes = recipes ?? <Recipe>[];

  final List<Recipe> recipes;

  @override
  Future<Recipe> saveRecipe(Recipe recipe) async {
    final saved = recipe.copyWith(userId: 'user-1');
    final index = recipes.indexWhere((item) => item.id == saved.id);
    if (index == -1) {
      recipes.add(saved);
    } else {
      recipes[index] = saved;
    }
    return saved;
  }

  @override
  Future<List<Recipe>> getForumRecipes() async => List.of(recipes);

  @override
  Future<List<Recipe>> getMyRecipes() async =>
      recipes.where((recipe) => recipe.userId == 'user-1').toList();

  @override
  Future<UserProfile> getCurrentProfile() async => const UserProfile(
    id: 'user-1',
    firstName: 'Manuel',
    lastName: 'Galindo',
    email: 'manuel@example.com',
    role: 'admin',
    status: 'activo',
  );

  @override
  Future<void> deleteRecipe(Recipe recipe) async {
    if (recipe.userId != 'user-1') {
      throw StateError('Solo puedes eliminar tus propias recetas.');
    }
    recipes.removeWhere((item) => item.id == recipe.id);
  }
}

void main() {
  testWidgets('login permite abrir registro e inicio', (
    WidgetTester tester,
  ) async {
    final authService = FakeAuthService();
    final recipeRepository = FakeRecipeRepository();
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      HorneaditosApp(
        authService: authService,
        recipeRepository: recipeRepository,
      ),
    );

    expect(find.text('Horneaditos'), findsOneWidget);
    expect(find.text('Qué bueno verte de nuevo.'), findsOneWidget);

    await tester.ensureVisible(find.text('Registrarme').first);
    await tester.tap(find.text('Registrarme').first);
    await tester.pumpAndSettle();
    expect(find.text('Algo dulce empieza aquí.'), findsOneWidget);
    expect(find.byKey(const ValueKey('register-name')), findsOneWidget);
    expect(find.byKey(const ValueKey('register-last-name')), findsOneWidget);
    expect(
      tester
          .widget<InputDecorator>(
            find.descendant(
              of: find.byKey(const ValueKey('register-name')),
              matching: find.byType(InputDecorator),
            ),
          )
          .decoration
          .hintText,
      'Ej: Pedro',
    );
    expect(
      tester
          .widget<InputDecorator>(
            find.descendant(
              of: find.byKey(const ValueKey('register-last-name')),
              matching: find.byType(InputDecorator),
            ),
          )
          .decoration
          .hintText,
      'Ej: Perez',
    );

    await tester.ensureVisible(find.text('Ya tengo una cuenta · Ingresar'));
    await tester.tap(find.text('Ya tengo una cuenta · Ingresar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('login-email')));
    await tester.enterText(
      find.byKey(const ValueKey('login-email')),
      'ana@correo.com',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('login-password')));
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      'dulce123',
    );
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(authService.signedInEmail, 'ana@correo.com');
    expect(find.text('Hoy se hornea.'), findsOneWidget);
    expect(find.text('Categorías'), findsOneWidget);

    await tester.ensureVisible(find.text('Agregar receta'));
    await tester.tap(find.text('Agregar receta'));
    await tester.pumpAndSettle();
    expect(find.text('Comparte tu toque especial.'), findsOneWidget);
    expect(find.byKey(const ValueKey('recipe-category')), findsOneWidget);
    expect(find.byKey(const ValueKey('recipe-ingredients')), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recipe-preparation')), findsOneWidget);
  });

  testWidgets('registro envía nombre y apellido y autentica la sesión', (
    WidgetTester tester,
  ) async {
    final authService = FakeAuthService();
    final recipeRepository = FakeRecipeRepository();
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      HorneaditosApp(
        authService: authService,
        recipeRepository: recipeRepository,
      ),
    );

    await tester.ensureVisible(find.text('Registrarme'));
    await tester.tap(find.text('Registrarme'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('register-name')));
    await tester.enterText(
      find.byKey(const ValueKey('register-name')),
      'Manuel',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('register-last-name')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-last-name')),
      'Galindo',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('register-email')));
    await tester.enterText(
      find.byKey(const ValueKey('register-email')),
      'manuel@example.com',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('register-password')));
    await tester.enterText(
      find.byKey(const ValueKey('register-password')),
      'secret123',
    );
    await tester.ensureVisible(find.text('Registrarme'));
    await tester.tap(find.text('Registrarme'));
    await tester.pumpAndSettle();

    expect(authService.registeredFirstName, 'Manuel');
    expect(authService.registeredLastName, 'Galindo');
    expect(authService.registeredEmail, 'manuel@example.com');
    expect(authService.registeredPassword, 'secret123');
    expect(find.text('Hoy se hornea.'), findsOneWidget);
    expect(find.text('Qué bueno verte de nuevo.'), findsNothing);
  });

  testWidgets('cerrar sesión vuelve al login y bloquea la app', (
    WidgetTester tester,
  ) async {
    final authService = FakeAuthService(initialSession: true);
    final recipeRepository = FakeRecipeRepository();
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      HorneaditosApp(
        authService: authService,
        recipeRepository: recipeRepository,
      ),
    );

    expect(find.text('Hoy se hornea.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sign-out')));
    await tester.pumpAndSettle();

    expect(find.text('Qué bueno verte de nuevo.'), findsOneWidget);
    expect(find.text('Hoy se hornea.'), findsNothing);
  });

  testWidgets('una sesión restaurada permite abrir la app sin login online', (
    WidgetTester tester,
  ) async {
    final authService = FakeAuthService(initialSession: true);
    final recipeRepository = FakeRecipeRepository();
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      HorneaditosApp(
        authService: authService,
        recipeRepository: recipeRepository,
      ),
    );

    expect(find.text('Hoy se hornea.'), findsOneWidget);
    expect(find.text('Qué bueno verte de nuevo.'), findsNothing);
  });

  testWidgets('perfil muestra recetas publicadas y permite abrir edición', (
    WidgetTester tester,
  ) async {
    final recipe = Recipe.create(
      category: 'CALIENTES',
      name: 'Galletas de chocolate',
      duration: '35 minutos',
      ingredients: 'Harina, cacao',
      preparation: 'Mezclar y hornear',
      userId: 'user-1',
    );
    final repository = FakeRecipeRepository(recipes: [recipe]);
    final authService = FakeAuthService(initialSession: true);
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ProfilePage(
          authService: authService,
          recipeRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manuel Galindo'), findsOneWidget);
    expect(find.text('Número de recetas publicadas'), findsOneWidget);
    expect(find.text('Galletas de chocolate'), findsOneWidget);

    await tester.ensureVisible(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(find.text('EDITAR RECETA'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('recipe-name')))
          .controller
          ?.text,
      'Galletas de chocolate',
    );
    await tester.enterText(
      find.byKey(const ValueKey('recipe-name')),
      'Galletas editadas',
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(repository.recipes.single.name, 'Galletas editadas');
    expect(find.text('Galletas editadas'), findsOneWidget);
  });

  testWidgets('publica recetas desde el formulario y actualiza el foro', (
    WidgetTester tester,
  ) async {
    final authService = FakeAuthService(initialSession: true);
    final repository = FakeRecipeRepository();
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      HorneaditosApp(authService: authService, recipeRepository: repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agregar receta'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recipe-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FRIOS').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('recipe-name')));
    await tester.enterText(
      find.byKey(const ValueKey('recipe-name')),
      'Ensalada fresca',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('recipe-duration')));
    await tester.enterText(
      find.byKey(const ValueKey('recipe-duration')),
      '20 minutos',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('recipe-ingredients')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('recipe-ingredients')),
      'Fruta y crema',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('recipe-preparation')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('recipe-preparation')),
      'Mezclar los ingredientes',
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Publicar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();

    expect(repository.recipes.single.name, 'Ensalada fresca');
    expect(repository.recipes.single.category, 'FRIOS');
    expect(find.text('Ensalada fresca'), findsOneWidget);
  });

  testWidgets('perfil permite borrar solo la receta propia y cambiar clave', (
    WidgetTester tester,
  ) async {
    final ownRecipe = Recipe.create(
      category: 'FRITOS',
      name: 'Buñuelos',
      duration: '30 minutos',
      ingredients: 'Harina',
      preparation: 'Freír',
      userId: 'user-1',
    );
    final otherRecipe = Recipe.create(
      category: 'FRIOS',
      name: 'Receta ajena',
      duration: '10 minutos',
      ingredients: 'Fruta',
      preparation: 'Cortar',
      userId: 'other-user',
    );
    final repository = FakeRecipeRepository(recipes: [ownRecipe, otherRecipe]);
    final authService = FakeAuthService(initialSession: true);
    addTearDown(authService.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ProfilePage(
          authService: authService,
          recipeRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Buñuelos'), findsOneWidget);
    expect(find.text('Receta ajena'), findsNothing);

    await tester.ensureVisible(find.byKey(ValueKey('delete-${ownRecipe.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('delete-${ownRecipe.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();
    expect(repository.recipes, contains(otherRecipe));
    expect(repository.recipes, isNot(contains(ownRecipe)));

    await tester.ensureVisible(find.byKey(const ValueKey('change-password')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('change-password')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('new-password')),
      'nueva123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('confirm-password')),
      'nueva123',
    );
    await tester.tap(find.text('Actualizar'));
    await tester.pumpAndSettle();
    expect(authService.updatedPassword, 'nueva123');
  });
}
