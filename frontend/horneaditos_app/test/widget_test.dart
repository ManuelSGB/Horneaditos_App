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
  Future<void> signOut() async {
    _hasSession = false;
    _authChanges.add(false);
  }

  Future<void> dispose() => _authChanges.close();
}

void main() {
  testWidgets('login permite abrir registro e inicio', (
    WidgetTester tester,
  ) async {
    final authService = FakeAuthService();
    addTearDown(authService.dispose);
    await tester.pumpWidget(HorneaditosApp(authService: authService));

    expect(find.text('Horneaditos'), findsOneWidget);
    expect(find.text('Qué bueno verte de nuevo.'), findsOneWidget);

    await tester.ensureVisible(find.text('Registrarme').first);
    await tester.tap(find.text('Registrarme').first);
    await tester.pumpAndSettle();
    expect(find.text('Algo dulce empieza aquí.'), findsOneWidget);
    expect(find.byKey(const ValueKey('register-name')), findsOneWidget);
    expect(find.byKey(const ValueKey('register-last-name')), findsOneWidget);

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
    addTearDown(authService.dispose);
    await tester.pumpWidget(HorneaditosApp(authService: authService));

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
    addTearDown(authService.dispose);
    await tester.pumpWidget(HorneaditosApp(authService: authService));

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
    addTearDown(authService.dispose);
    await tester.pumpWidget(HorneaditosApp(authService: authService));

    expect(find.text('Hoy se hornea.'), findsOneWidget);
    expect(find.text('Qué bueno verte de nuevo.'), findsNothing);
  });

  testWidgets('perfil muestra recetas publicadas y permite abrir edición', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));

    expect(find.text('Lucía Martín'), findsOneWidget);
    expect(find.text('Número de recetas publicadas'), findsOneWidget);
    expect(find.text('Galletas de chocolate'), findsOneWidget);

    await tester.ensureVisible(find.text('Editar'));
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(find.text('CALIENTES'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('recipe-name')))
          .controller
          ?.text,
      'Galletas de chocolate',
    );
  });
}
