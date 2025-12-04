import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'recipes_event.dart';
import 'recipes_state.dart';
import '../models/recipe.dart';
import '../repositories/recipes_repository.dart';

class RecipesBloc extends Bloc<RecipesEvent, RecipesState> {
  final RecipesRepository _recipesRepository;
  StreamSubscription<List<Recipe>>? _recipesSubscription;
  
  List<Recipe> _allRecipes = [];
  List<Recipe> _filteredRecipes = [];
  String _currentSearchQuery = '';
  String _currentCategory = 'Всі';

  RecipesBloc({required RecipesRepository recipesRepository})
      : _recipesRepository = recipesRepository,
        super(RecipesDataState(data: [])) {
    on<RefreshRecipesEvent>(_onRefreshRecipesEvent);
    on<SearchRecipesEvent>(_onSearchRecipesEvent);
    on<FilterByCategoryEvent>(_onFilterByCategoryEvent);
    on<SortRecipesEvent>(_onSortRecipesEvent);
    on<_RecipesUpdatedEvent>(_onRecipesUpdatedEvent);
    on<_RecipesErrorEvent>(_onRecipesErrorEvent);
    on<DeleteRecipeEvent>(_onDeleteRecipeEvent);
  }

  Future<void> _onRefreshRecipesEvent(
    RefreshRecipesEvent event,
    Emitter<RecipesState> emit,
  ) async {
    emit(RecipesLoadingState(data: state.data, selectedCategory: _currentCategory));

    try {
      await _recipesSubscription?.cancel();
      _recipesSubscription = _recipesRepository.getRecipes().listen(
        (recipes) {
          add(_RecipesUpdatedEvent(recipes));
        },
        onError: (error) {
          add(_RecipesErrorEvent(error.toString()));
        },
      );
    } catch (e) {
      emit(RecipesErrorState(
        error: 'Не вдалося завантажити рецепти: ${e.toString()}',
        data: state.data,
        selectedCategory: _currentCategory,
      ));
    }
  }

  Future<void> _onRecipesUpdatedEvent(
    _RecipesUpdatedEvent event,
    Emitter<RecipesState> emit,
  ) async {
    _allRecipes = event.recipes;
    _applyFilters();
    emit(RecipesDataState(data: _filteredRecipes, selectedCategory: _currentCategory));
  }

  Future<void> _onRecipesErrorEvent(
    _RecipesErrorEvent event,
    Emitter<RecipesState> emit,
  ) async {
    emit(RecipesErrorState(
      error: 'Помилка завантаження рецептів: ${event.error}',
      data: state.data,
      selectedCategory: _currentCategory,
    ));
  }

  Future<void> _onSearchRecipesEvent(
    SearchRecipesEvent event,
    Emitter<RecipesState> emit,
  ) async {
    _currentSearchQuery = event.query.toLowerCase();
    _applyFilters();
    emit(RecipesDataState(data: _filteredRecipes, selectedCategory: _currentCategory));
  }

  Future<void> _onFilterByCategoryEvent(
    FilterByCategoryEvent event,
    Emitter<RecipesState> emit,
  ) async {
    _currentCategory = event.category;
    _applyFilters();
    emit(RecipesDataState(data: _filteredRecipes, selectedCategory: _currentCategory));
  }

  Future<void> _onSortRecipesEvent(
    SortRecipesEvent event,
    Emitter<RecipesState> emit,
  ) async {
    emit(RecipesLoadingState(data: state.data, selectedCategory: _currentCategory));

    await Future.delayed(const Duration(milliseconds: 300));

    switch (event.sortType) {
      case RecipeSortType.nameAsc:
        _filteredRecipes.sort((a, b) => a.name.compareTo(b.name));
        break;
      case RecipeSortType.nameDesc:
        _filteredRecipes.sort((a, b) => b.name.compareTo(a.name));
        break;
      case RecipeSortType.ratingDesc:
        _filteredRecipes.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case RecipeSortType.caloriesAsc:
        _filteredRecipes.sort((a, b) => a.calories.compareTo(b.calories));
        break;
      case RecipeSortType.timeAsc:
        _filteredRecipes.sort((a, b) {
          int timeA = _parseTime(a.time);
          int timeB = _parseTime(b.time);
          return timeA.compareTo(timeB);
        });
        break;
    }

    emit(RecipesDataState(data: _filteredRecipes, selectedCategory: _currentCategory));
  }

  Future<void> _onDeleteRecipeEvent(
    DeleteRecipeEvent event,
    Emitter<RecipesState> emit,
  ) async {
    try {
      await _recipesRepository.deleteRecipe(event.recipeId);
    } catch (e) {
      emit(RecipesErrorState(
        error: 'Помилка видалення рецепту: ${e.toString()}',
        data: state.data,
        selectedCategory: _currentCategory,
      ));
    }
  }

  void _applyFilters() {
    _filteredRecipes = List.from(_allRecipes);

    // Фільтр за категорією
    if (_currentCategory != 'Всі') {
      _filteredRecipes = _filteredRecipes
          .where((recipe) => recipe.category == _currentCategory)
          .toList();
    }

    // Фільтр за пошуковим запитом
    if (_currentSearchQuery.isNotEmpty) {
      _filteredRecipes = _filteredRecipes.where((recipe) {
        return recipe.name.toLowerCase().contains(_currentSearchQuery) ||
            recipe.category.toLowerCase().contains(_currentSearchQuery) ||
            recipe.description.toLowerCase().contains(_currentSearchQuery) ||
            recipe.ingredients.any(
                (ingredient) => ingredient.toLowerCase().contains(_currentSearchQuery));
      }).toList();
    }
  }

  int _parseTime(String time) {
    final match = RegExp(r'(\d+)').firstMatch(time);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 0;
  }

  @override
  Future<void> close() {
    _recipesSubscription?.cancel();
    return super.close();
  }
}

class _RecipesUpdatedEvent extends RecipesEvent {
  final List<Recipe> recipes;
  _RecipesUpdatedEvent(this.recipes);
}

class _RecipesErrorEvent extends RecipesEvent {
  final String error;
  _RecipesErrorEvent(this.error);
}
