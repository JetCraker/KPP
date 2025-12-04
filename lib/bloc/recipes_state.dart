import '../models/recipe.dart';

abstract class RecipesState {
  final List<Recipe> data;
  final String selectedCategory;

  RecipesState({
    required this.data,
    this.selectedCategory = 'Всі',
  });
}

class RecipesLoadingState extends RecipesState {
  RecipesLoadingState({required super.data, super.selectedCategory});
}

class RecipesDataState extends RecipesState {
  RecipesDataState({required super.data, super.selectedCategory});
}

class RecipesErrorState extends RecipesState {
  final String error;

  RecipesErrorState({
    required this.error,
    required super.data,
    super.selectedCategory,
  });
}
