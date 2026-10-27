// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:horneaditos_app/main.dart';

void main() {
  testWidgets('login permite abrir registro e inicio', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HorneaditosApp());

    expect(find.text('Horneaditos'), findsOneWidget);
    expect(find.text('Qué bueno verte de nuevo.'), findsOneWidget);

    await tester.ensureVisible(find.text('Registrarme').first);
    await tester.tap(find.text('Registrarme').first);
    await tester.pumpAndSettle();
    expect(find.text('Algo dulce empieza aquí.'), findsOneWidget);

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
