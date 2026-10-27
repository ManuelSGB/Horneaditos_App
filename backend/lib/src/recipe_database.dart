import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'recipe.dart';

class RecipeDatabase {
  static const _databaseName = 'horneaditos.db';
  static const _databaseVersion = 3;

  Database? _database;

  Future<void> open() async {
    if (_database != null) {
      return;
    }

    final databasePath = await getDatabasesPath();
    _database = await openDatabase(
      path.join(databasePath, _databaseName),
      version: _databaseVersion,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await _createSchema(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createSchema(database);
          await _migrateLegacyRecipes(database);
        }
        if (oldVersion < 3) {
          await _migrateRecipeCategories(database);
        }
      },
    );
  }

  Future<void> cacheAuthenticatedUser(User user) async {
    final email = user.email ?? '${user.id}@local.invalid';
    final emailName = email.split('@').first;
    final firstName = user.userMetadata?['nombre'] as String? ?? emailName;
    final lastName = user.userMetadata?['apellido'] as String? ?? 'Usuario';
    final database = _requireDatabase();
    await database.transaction((transaction) async {
      final values = {
        'id': user.id,
        'nombre': firstName,
        'apellido': lastName,
        'correo': email,
        'rol': 'user',
        'estado': 'activo',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'sincronizado': 1,
      };
      final existing = await transaction.query(
        'users',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [user.id],
        limit: 1,
      );
      if (existing.isEmpty) {
        await transaction.insert('users', values);
      } else {
        await transaction.update(
          'users',
          values..remove('id'),
          where: 'id = ?',
          whereArgs: [user.id],
        );
      }
    });
  }

  Future<Recipe> save(Recipe recipe) async {
    final database = _requireDatabase();
    return database.transaction((transaction) async {
      final previous = await transaction.query(
        'foro',
        columns: ['updated_at'],
        where: 'id = ?',
        whereArgs: [recipe.id],
        limit: 1,
      );
      var recipeToSave = recipe;
      if (previous.isNotEmpty) {
        final previousUpdatedAt = DateTime.parse(
          previous.single['updated_at']! as String,
        );
        if (!recipe.updatedAt.isAfter(previousUpdatedAt)) {
          recipeToSave = recipe.copyWith(
            updatedAt: previousUpdatedAt.add(const Duration(microseconds: 1)),
          );
        }
      }

      await transaction.insert(
        'foro',
        recipeToSave.toLocalMap(sincronizado: false),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return recipeToSave;
    });
  }

  Future<List<Recipe>> getAll() async {
    final rows = await _requireDatabase().query(
      'foro',
      orderBy: 'created_at DESC',
    );
    return rows.map(Recipe.fromLocalMap).toList(growable: false);
  }

  Future<List<Recipe>> getPending({required String userId}) async {
    final rows = await _requireDatabase().query(
      'foro',
      where: 'sincronizado = 0 AND user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );
    return rows.map(Recipe.fromLocalMap).toList(growable: false);
  }

  Future<void> markSynchronized(Recipe uploadedRecipe) async {
    await _requireDatabase().update(
      'foro',
      {'sincronizado': 1},
      where: 'id = ? AND updated_at = ? AND sincronizado = 0',
      whereArgs: [
        uploadedRecipe.id,
        uploadedRecipe.updatedAt.toUtc().toIso8601String(),
      ],
    );
  }

  Future<void> mergeRemote(Recipe recipe) async {
    await _requireDatabase().rawInsert(
      '''
      INSERT INTO foro (
        id, user_id, categoria, nombre, duracion, ingredientes, preparacion,
        imagen, created_at, updated_at, sincronizado
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
      ON CONFLICT(id) DO UPDATE SET
        user_id = excluded.user_id,
        categoria = excluded.categoria,
        nombre = excluded.nombre,
        duracion = excluded.duracion,
        ingredientes = excluded.ingredientes,
        preparacion = excluded.preparacion,
        imagen = excluded.imagen,
        created_at = excluded.created_at,
        updated_at = excluded.updated_at,
        sincronizado = 1
      WHERE foro.sincronizado = 1
      ''',
      [
        recipe.id,
        recipe.userId,
        recipe.category,
        recipe.name,
        recipe.duration,
        recipe.ingredients,
        recipe.preparation,
        recipe.imageUrl,
        recipe.createdAt.toUtc().toIso8601String(),
        recipe.updatedAt.toUtc().toIso8601String(),
      ],
    );
  }

  Future<void> close() async {
    final database = _database;
    _database = null;
    await database?.close();
  }

  Future<void> _createSchema(DatabaseExecutor database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        apellido TEXT NOT NULL,
        correo TEXT NOT NULL UNIQUE,
        rol TEXT NOT NULL DEFAULT 'user' CHECK (rol IN ('admin', 'user')),
        estado TEXT NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo')),
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        sincronizado INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS foro (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        categoria TEXT NOT NULL CHECK (categoria IN ('FRIOS', 'FRITOS', 'CALIENTES')),
        nombre TEXT NOT NULL,
        duracion TEXT NOT NULL,
        ingredientes TEXT NOT NULL,
        preparacion TEXT NOT NULL,
        imagen TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        sincronizado INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id)
          ON DELETE CASCADE ON UPDATE CASCADE
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS foro_sync_index '
      'ON foro (sincronizado, user_id)',
    );
  }

  Future<void> _migrateLegacyRecipes(DatabaseExecutor database) async {
    final legacyTable = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'recetas'",
    );
    if (legacyTable.isEmpty) {
      return;
    }

    await database.execute('''
      INSERT OR IGNORE INTO users (
        id, nombre, apellido, correo, rol, estado, sincronizado
      )
      SELECT DISTINCT user_id, 'Usuario', 'Local',
        user_id || '@local.invalid', 'user', 'activo', 1
      FROM recetas
      WHERE user_id IS NOT NULL
    ''');
    await database.execute('''
      INSERT OR IGNORE INTO foro (
        id, user_id, categoria, nombre, duracion, ingredientes,
        preparacion, imagen, created_at, updated_at, sincronizado
      )
      SELECT id, user_id,
        CASE
          WHEN category IN ('FRIOS', 'FRITOS', 'CALIENTES') THEN category
          ELSE 'CALIENTES'
        END,
        name, duration, ingredients,
        preparation, image_url, created_at, updated_at, sincronizado
      FROM recetas
      WHERE user_id IS NOT NULL
    ''');
  }

  Future<void> _migrateRecipeCategories(DatabaseExecutor database) async {
    final tables = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'foro'",
    );
    if (tables.isEmpty) {
      return;
    }

    await database.execute('DROP INDEX IF EXISTS foro_sync_index');
    await database.execute('ALTER TABLE foro RENAME TO foro_old_categories');
    await database.execute('''
      CREATE TABLE foro (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        categoria TEXT NOT NULL CHECK (categoria IN ('FRIOS', 'FRITOS', 'CALIENTES')),
        nombre TEXT NOT NULL,
        duracion TEXT NOT NULL,
        ingredientes TEXT NOT NULL,
        preparacion TEXT NOT NULL,
        imagen TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        sincronizado INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id)
          ON DELETE CASCADE ON UPDATE CASCADE
      )
    ''');
    await database.execute('''
      INSERT INTO foro (
        id, user_id, categoria, nombre, duracion, ingredientes,
        preparacion, imagen, created_at, updated_at, sincronizado
      )
      SELECT id, user_id,
        CASE
          WHEN categoria IN ('FRIOS', 'FRITOS', 'CALIENTES') THEN categoria
          ELSE 'CALIENTES'
        END,
        nombre, duracion, ingredientes, preparacion, imagen,
        created_at, updated_at, sincronizado
      FROM foro_old_categories
    ''');
    await database.execute('DROP TABLE foro_old_categories');
    await database.execute(
      'CREATE INDEX foro_sync_index ON foro (sincronizado, user_id)',
    );
  }

  Database _requireDatabase() {
    final database = _database;
    if (database == null) {
      throw StateError('RecipeDatabase.open() must be called before use.');
    }
    return database;
  }
}
