import 'package:flutter_test/flutter_test.dart';
import 'package:horneaditos_backend/horneaditos_backend.dart';

void main() {
  test('Recipe.create generates a UUID and starts unsynchronized', () {
    final recipe = Recipe.create(
      category: 'CALIENTES',
      name: 'Pastel de chocolate',
      duration: '45 minutos',
      ingredients: 'Harina y cacao',
      preparation: 'Mezclar y hornear',
    );

    expect(
      recipe.id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(recipe.sincronizado, isFalse);
  });

  test('Recipe local map round-trip retains fields and sync state', () {
    final recipe = Recipe.create(
      category: 'FRIOS',
      name: 'Galletas de avena',
      duration: '25 minutos',
      ingredients: 'Avena',
      preparation: 'Hornear',
      imageUrl: 'https://example.com/galletas.jpg',
      userId: 'user-1',
    );

    final restored = Recipe.fromLocalMap(recipe.toLocalMap(sincronizado: true));

    expect(restored.id, recipe.id);
    expect(restored.userId, 'user-1');
    expect(restored.category, 'FRIOS');
    expect(restored.name, 'Galletas de avena');
    expect(restored.duration, '25 minutos');
    expect(restored.ingredients, 'Avena');
    expect(restored.preparation, 'Hornear');
    expect(restored.imageUrl, 'https://example.com/galletas.jpg');
    expect(restored.sincronizado, isTrue);
  });

  test('Recipe Supabase map uses the foro table column names', () {
    final recipe = Recipe.create(
      category: 'FRITOS',
      name: 'Pan dulce',
      duration: '50 minutos',
      ingredients: 'Harina y levadura',
      preparation: 'Amasar y hornear',
      imageUrl: 'images/pan.jpg',
      userId: 'user-1',
    );

    final remote = recipe.toSupabaseMap(userId: 'user-1');
    final restored = Recipe.fromSupabaseMap(remote);

    expect(
      remote.keys,
      containsAll([
        'id',
        'user_id',
        'categoria',
        'nombre',
        'duracion',
        'ingredientes',
        'preparacion',
        'imagen',
        'created_at',
        'updated_at',
      ]),
    );
    expect(restored.category, 'FRITOS');
    expect(restored.name, 'Pan dulce');
    expect(restored.imageUrl, 'images/pan.jpg');
    expect(restored.sincronizado, isTrue);
  });
}
