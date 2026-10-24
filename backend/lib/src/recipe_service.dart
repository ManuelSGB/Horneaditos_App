import 'dart:async';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'recipe.dart';
import 'recipe_database.dart';

class RecipeService {
  RecipeService({
    required RecipeDatabase database,
    required SupabaseClient client,
    required Connectivity connectivity,
  }) : _database = database,
       _client = client,
       _connectivity = connectivity;

  static const _table = 'foro';

  final RecipeDatabase _database;
  final SupabaseClient _client;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<dynamic>? _authSubscription;
  Future<int> _syncQueue = Future<int>.value(0);

  Future<void> start() async {
    await _connectivitySubscription?.cancel();
    final currentUser = _client.auth.currentUser;
    if (currentUser != null) {
      await _database.cacheAuthenticatedUser(currentUser);
    }
    await _authSubscription?.cancel();
    _authSubscription = _client.auth.onAuthStateChange.listen(
      (authState) {
        final user = authState.session?.user;
        if (user != null &&
            (authState.event == AuthChangeEvent.initialSession ||
                authState.event == AuthChangeEvent.signedIn)) {
          unawaited(_cacheAndRestoreUser(user));
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        developer.log(
          'No se pudo observar el estado de autenticación.',
          name: 'horneaditos.auth',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        if (results.any((result) => result != ConnectivityResult.none)) {
          unawaited(_syncInBackground());
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        developer.log(
          'No se pudo observar el estado de conectividad.',
          name: 'horneaditos.sync',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    unawaited(_syncInBackground());
  }

  Future<Recipe> saveRecipe(Recipe recipe) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Inicia sesión para guardar una receta.');
    }
    await _database.cacheAuthenticatedUser(user);
    final now = DateTime.now().toUtc();
    final localRecipe = recipe.copyWith(
      userId: user.id,
      updatedAt: now.isAfter(recipe.updatedAt)
          ? now
          : recipe.updatedAt.add(const Duration(microseconds: 1)),
      sincronizado: false,
    );
    final savedRecipe = await _database.save(localRecipe);
    unawaited(_syncInBackground());
    return savedRecipe;
  }

  Future<List<Recipe>> getRecipes() {
    return _database.getAll();
  }

  Future<int> syncPending() {
    final next = _syncQueue.then<int>(
      (_) => _syncPending(),
      onError: (Object error, StackTrace stackTrace) => _syncPending(),
    );
    _syncQueue = next;
    return next;
  }

  Future<int> _syncPending() async {
    final user = _client.auth.currentUser;
    if (user == null || !await _hasNetworkConnection()) {
      return 0;
    }

    final pending = await _database.getPending(userId: user.id);
    if (pending.isEmpty) {
      return 0;
    }

    try {
      await _upsertRemoteUser(user);
    } on Exception catch (error, stackTrace) {
      developer.log(
        'No se pudo registrar el usuario remoto; no se subirán sus recetas.',
        name: 'horneaditos.sync',
        error: error,
        stackTrace: stackTrace,
      );
      return 0;
    }

    var uploadedCount = 0;
    for (final recipe in pending) {
      try {
        await _client
            .from(_table)
            .upsert(recipe.toSupabaseMap(userId: user.id), onConflict: 'id');
      } on Exception catch (error, stackTrace) {
        developer.log(
          'No se pudo sincronizar la receta ${recipe.id}; seguirá pendiente.',
          name: 'horneaditos.sync',
          error: error,
          stackTrace: stackTrace,
        );
        continue;
      }
      await _database.markSynchronized(recipe);
      uploadedCount++;
    }
    return uploadedCount;
  }

  Future<List<Recipe>> restoreRecipesForCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError(
        'Se necesita una sesión de Supabase para restaurar recetas.',
      );
    }

    await _upsertRemoteUser(user);

    const pageSize = 1000;
    final rows = <Map<String, dynamic>>[];
    for (var offset = 0; ; offset += pageSize) {
      final page = await _client
          .from(_table)
          .select()
          .eq('user_id', user.id)
          .order('id')
          .range(offset, offset + pageSize - 1);
      rows.addAll(page);
      if (page.length < pageSize) {
        break;
      }
    }
    final restoredRecipes = rows
        .map(Recipe.fromSupabaseMap)
        .toList(growable: false);
    for (final recipe in restoredRecipes) {
      await _database.mergeRemote(recipe);
    }

    unawaited(_syncInBackground());
    return _database.getAll();
  }

  Future<void> _syncInBackground() async {
    try {
      await syncPending();
    } on Exception catch (error, stackTrace) {
      developer.log(
        'Falló la sincronización de recetas pendientes.',
        name: 'horneaditos.sync',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _cacheAuthenticatedUser(User user) async {
    try {
      await _database.cacheAuthenticatedUser(user);
    } on Exception catch (error, stackTrace) {
      developer.log(
        'No se pudo guardar el perfil del usuario en SQLite.',
        name: 'horneaditos.auth',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _cacheAndRestoreUser(User user) async {
    await _cacheAuthenticatedUser(user);
    try {
      await _upsertRemoteUser(user);
      await restoreRecipesForCurrentUser();
    } on Exception catch (error, stackTrace) {
      developer.log(
        'No se pudieron restaurar las recetas de Supabase.',
        name: 'horneaditos.restore',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _upsertRemoteUser(User user) async {
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw StateError(
        'El esquema public.users requiere correo; '
        'la sesión Supabase debe tener un email.',
      );
    }

    final emailName = email.split('@').first;
    await _client.from('users').upsert({
      'id': user.id,
      'nombre': user.userMetadata?['nombre'] as String? ?? emailName,
      'apellido': user.userMetadata?['apellido'] as String? ?? 'Usuario',
      'correo': email,
    }, onConflict: 'id');
  }

  Future<bool> _hasNetworkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } on Exception catch (error, stackTrace) {
      developer.log(
        'No se pudo comprobar la conectividad; se conservará la cola local.',
        name: 'horneaditos.sync',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    await _authSubscription?.cancel();
    _authSubscription = null;
  }
}
