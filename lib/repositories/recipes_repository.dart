import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../models/recipe.dart';

abstract class RecipesRepository {

  Stream<List<Recipe>> getRecipes();

  Stream<List<Recipe>> getUserRecipes(String userId);

  Future<Recipe?> getRecipeById(String recipeId);

  Future<String> addRecipe(Recipe recipe);
  
  Future<void> updateRecipe(Recipe recipe);
  
  Future<void> deleteRecipe(String recipeId);
  
  Stream<List<Recipe>> searchRecipes(String query);
  
  Stream<List<Recipe>> getRecipesByCategory(String category);
}

class FirebaseRecipesRepository implements RecipesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  static const String _collectionName = 'recipes';
  
  CollectionReference<Map<String, dynamic>> get _recipesCollection =>
      _firestore.collection(_collectionName);

  @override
  Stream<List<Recipe>> getRecipes() {
    return _recipesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Recipe.fromJson(data);
      }).toList();
    });
  }

  @override
  Stream<List<Recipe>> getUserRecipes(String userId) {
    return _recipesCollection
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Recipe.fromJson(data);
      }).toList();
    });
  }

  @override
  Future<Recipe?> getRecipeById(String recipeId) async {
    try {
      final doc = await _recipesCollection.doc(recipeId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Recipe.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Помилка отримання рецепту: ${e.toString()}');
    }
  }

  @override
  Future<String> addRecipe(Recipe recipe) async {
    try {
      final recipeData = recipe.toJson();
      recipeData.remove('id'); // Видаляємо id, бо Firestore створить свій
      recipeData['createdAt'] = FieldValue.serverTimestamp();
      recipeData['updatedAt'] = FieldValue.serverTimestamp();
      
      final docRef = await _recipesCollection.add(recipeData);

      await _analytics.logEvent(
        name: 'recipe_created',
        parameters: {
          'recipe_id': docRef.id,
          'recipe_name': recipe.name,
          'category': recipe.category,
        },
      );
      
      return docRef.id;
    } catch (e) {
      throw Exception('Помилка додавання рецепту: ${e.toString()}');
    }
  }

  @override
  Future<void> updateRecipe(Recipe recipe) async {
    try {
      final recipeData = recipe.toJson();
      recipeData.remove('id');
      recipeData.remove('createdAt');
      recipeData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _recipesCollection.doc(recipe.id).update(recipeData);
      
      await _analytics.logEvent(
        name: 'recipe_updated',
        parameters: {
          'recipe_id': recipe.id,
          'recipe_name': recipe.name,
        },
      );
    } catch (e) {
      throw Exception('Помилка оновлення рецепту: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _recipesCollection.doc(recipeId).delete();
      
      await _analytics.logEvent(
        name: 'recipe_deleted',
        parameters: {
          'recipe_id': recipeId,
        },
      );
    } catch (e) {
      throw Exception('Помилка видалення рецепту: ${e.toString()}');
    }
  }

  @override
  Stream<List<Recipe>> searchRecipes(String query) {
    if (query.isEmpty) {
      return getRecipes();
    }
    
    final lowerQuery = query.toLowerCase();
    
    return _recipesCollection
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Recipe.fromJson(data);
          })
          .where((recipe) {
            return recipe.name.toLowerCase().contains(lowerQuery) ||
                   recipe.category.toLowerCase().contains(lowerQuery) ||
                   recipe.description.toLowerCase().contains(lowerQuery) ||
                   recipe.ingredients.any((i) => i.toLowerCase().contains(lowerQuery));
          })
          .toList();
    });
  }

  @override
  Stream<List<Recipe>> getRecipesByCategory(String category) {
    if (category == 'Всі') {
      return getRecipes();
    }
    
    return _recipesCollection
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Recipe.fromJson(data);
      }).toList();
    });
  }
}
