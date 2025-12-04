class Recipe {
  final String id;
  final String name;
  final String category;
  final String time;
  final int calories;
  final double rating;
  final String emoji;
  final String description;
  final List<String> ingredients;
  final List<String> steps;
  final String difficulty;
  final int servings;
  final String? authorId;
  final String? authorName;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Recipe({
    required this.id,
    required this.name,
    required this.category,
    required this.time,
    required this.calories,
    required this.rating,
    required this.emoji,
    this.description = '',
    this.ingredients = const [],
    this.steps = const [],
    this.difficulty = 'Середня',
    this.servings = 4,
    this.authorId,
    this.authorName,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  Recipe copyWith({
    String? id,
    String? name,
    String? category,
    String? time,
    int? calories,
    double? rating,
    String? emoji,
    String? description,
    List<String>? ingredients,
    List<String>? steps,
    String? difficulty,
    int? servings,
    String? authorId,
    String? authorName,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      time: time ?? this.time,
      calories: calories ?? this.calories,
      rating: rating ?? this.rating,
      emoji: emoji ?? this.emoji,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      difficulty: difficulty ?? this.difficulty,
      servings: servings ?? this.servings,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'time': time,
      'calories': calories,
      'rating': rating,
      'emoji': emoji,
      'description': description,
      'ingredients': ingredients,
      'steps': steps,
      'difficulty': difficulty,
      'servings': servings,
      'authorId': authorId,
      'authorName': authorName,
      'imageUrl': imageUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      time: json['time'] as String,
      calories: json['calories'] as int,
      rating: (json['rating'] as num).toDouble(),
      emoji: json['emoji'] as String,
      description: json['description'] as String? ?? '',
      ingredients: (json['ingredients'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      steps: (json['steps'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      difficulty: json['difficulty'] as String? ?? 'Середня',
      servings: json['servings'] as int? ?? 4,
      authorId: json['authorId'] as String?,
      authorName: json['authorName'] as String?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  // Helper method to parse both Timestamp and String dates
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    // If it's a Firestore Timestamp
    if (value.runtimeType.toString() == 'Timestamp') {
      return (value as dynamic).toDate() as DateTime;
    }
    
    // If it's a String (ISO8601)
    if (value is String) {
      return DateTime.parse(value);
    }
    
    // If it's already a DateTime
    if (value is DateTime) {
      return value;
    }
    
    return null;
  }
}