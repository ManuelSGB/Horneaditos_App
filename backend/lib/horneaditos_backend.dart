import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/recipe.dart';
import 'src/recipe_database.dart';
import 'src/recipe_service.dart';

export 'src/recipe.dart';
export 'src/recipe_database.dart';
export 'src/recipe_service.dart';

class HorneaditosBackend {
  HorneaditosBackend._({required this.database, required this.recipes});

  static HorneaditosBackend? _instance;
  static Future<HorneaditosBackend>? _initializing;

  final RecipeDatabase database;
  final RecipeService recipes;

  static Future<HorneaditosBackend> initialize({
    required String supabaseUrl,
    required String supabasePublishableKey,
  }) async {
    final instance = _instance;
    if (instance != null) {
      return instance;
    }

    final initializing = _initializing;
    if (initializing != null) {
      return initializing;
    }

    final future = _create(
      supabaseUrl: supabaseUrl,
      supabasePublishableKey: supabasePublishableKey,
    );
    _initializing = future;
    try {
      final backend = await future;
      _instance = backend;
      return backend;
    } finally {
      _initializing = null;
    }
  }

  static Future<HorneaditosBackend> _create({
    required String supabaseUrl,
    required String supabasePublishableKey,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );

    final database = RecipeDatabase();
    await database.open();
    final recipes = RecipeService(
      database: database,
      client: Supabase.instance.client,
      connectivity: Connectivity(),
    );
    await recipes.start();

    return HorneaditosBackend._(database: database, recipes: recipes);
  }

  Future<List<Recipe>> restoreRecipesForCurrentUser() {
    return recipes.restoreRecipesForCurrentUser();
  }

  Future<void> dispose() async {
    await recipes.dispose();
    await database.close();
    if (identical(_instance, this)) {
      _instance = null;
    }
  }
}
