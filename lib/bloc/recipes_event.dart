abstract class RecipesEvent {}

class RefreshRecipesEvent extends RecipesEvent {}

class SearchRecipesEvent extends RecipesEvent {
  final String query;

  SearchRecipesEvent(this.query);
}

class FilterByCategoryEvent extends RecipesEvent {
  final String category;

  FilterByCategoryEvent(this.category);
}

class SortRecipesEvent extends RecipesEvent {
  final RecipeSortType sortType;

  SortRecipesEvent(this.sortType);
}

class DeleteRecipeEvent extends RecipesEvent {
  final String recipeId;

  DeleteRecipeEvent(this.recipeId);
}

enum RecipeSortType {
  nameAsc,
  nameDesc,
  ratingDesc,
  caloriesAsc,
  timeAsc,
}
