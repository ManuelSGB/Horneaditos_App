import 'package:uuid/uuid.dart';

class Recipe {
  const Recipe({
    required this.id,
    required this.category,
    required this.name,
    required this.duration,
    required this.ingredients,
    required this.preparation,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.userId,
    this.sincronizado = false,
  });

  factory Recipe.create({
    required String category,
    required String name,
    required String duration,
    required String ingredients,
    required String preparation,
    String? imageUrl,
    String? userId,
  }) {
    final now = DateTime.now().toUtc();
    return Recipe(
      id: const Uuid().v4(),
      category: category,
      name: name,
      duration: duration,
      ingredients: ingredients,
      preparation: preparation,
      imageUrl: imageUrl,
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );
  }

  final String id;
  final String? userId;
  final String category;
  final String name;
  final String duration;
  final String ingredients;
  final String preparation;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool sincronizado;

  Recipe copyWith({
    String? userId,
    String? category,
    String? name,
    String? duration,
    String? ingredients,
    String? preparation,
    String? imageUrl,
    bool clearImageUrl = false,
    DateTime? updatedAt,
    bool? sincronizado,
  }) {
    return Recipe(
      id: id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      ingredients: ingredients ?? this.ingredients,
      preparation: preparation ?? this.preparation,
      imageUrl: clearImageUrl ? null : imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }

  factory Recipe.fromLocalMap(Map<String, Object?> map) {
    return Recipe(
      id: map['id']! as String,
      userId: map['user_id'] as String?,
      category: map['categoria']! as String,
      name: map['nombre']! as String,
      duration: map['duracion']! as String,
      ingredients: map['ingredientes']! as String,
      preparation: map['preparacion']! as String,
      imageUrl: map['imagen'] as String?,
      createdAt: DateTime.parse(map['created_at']! as String).toUtc(),
      updatedAt: DateTime.parse(map['updated_at']! as String).toUtc(),
      sincronizado: map['sincronizado']! as int == 1,
    );
  }

  factory Recipe.fromSupabaseMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      category: map['categoria'] as String,
      name: map['nombre'] as String,
      duration: map['duracion'] as String,
      ingredients: map['ingredientes'] as String,
      preparation: map['preparacion'] as String,
      imageUrl: map['imagen'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toUtc(),
      sincronizado: true,
    );
  }

  Map<String, Object?> toLocalMap({required bool sincronizado}) {
    return {
      'id': id,
      'user_id': userId,
      'categoria': category,
      'nombre': name,
      'duracion': duration,
      'ingredientes': ingredients,
      'preparacion': preparation,
      'imagen': imageUrl,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'sincronizado': sincronizado ? 1 : 0,
    };
  }

  Map<String, Object?> toSupabaseMap({required String userId}) {
    return {
      'id': id,
      'user_id': userId,
      'categoria': category,
      'nombre': name,
      'duracion': duration,
      'ingredientes': ingredients,
      'preparacion': preparation,
      'imagen': imageUrl,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
