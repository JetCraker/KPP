import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/recipe.dart';
import '../repositories/recipes_repository.dart';
import '../repositories/storage_repository.dart';

// Events
abstract class UpdateRecipeEvent {}

class UpdateRecipeSubmitEvent extends UpdateRecipeEvent {
  final Recipe recipe;
  final File? newImageFile;
  final bool removeExistingImage;

  UpdateRecipeSubmitEvent({
    required this.recipe,
    this.newImageFile,
    this.removeExistingImage = false,
  });
}

class UpdateRecipeResetEvent extends UpdateRecipeEvent {}

// States
abstract class UpdateRecipeState {}

class UpdateRecipeInitialState extends UpdateRecipeState {}

class RecipeUpdatingState extends UpdateRecipeState {}

class RecipeUpdateSuccessState extends UpdateRecipeState {
  final String recipeId;

  RecipeUpdateSuccessState(this.recipeId);
}

class RecipeUpdateErrorState extends UpdateRecipeState {
  final String error;

  RecipeUpdateErrorState(this.error);
}

// BLoC
class UpdateRecipeBloc extends Bloc<UpdateRecipeEvent, UpdateRecipeState> {
  final RecipesRepository _recipesRepository;
  final StorageRepository _storageRepository;

  UpdateRecipeBloc({
    required RecipesRepository recipesRepository,
    required StorageRepository storageRepository,
  })  : _recipesRepository = recipesRepository,
        _storageRepository = storageRepository,
        super(UpdateRecipeInitialState()) {
    on<UpdateRecipeSubmitEvent>(_onUpdateRecipeSubmit);
    on<UpdateRecipeResetEvent>(_onUpdateRecipeReset);
  }

  Future<void> _onUpdateRecipeSubmit(
    UpdateRecipeSubmitEvent event,
    Emitter<UpdateRecipeState> emit,
  ) async {
    emit(RecipeUpdatingState());

    try {
      String? imageUrl = event.recipe.imageUrl;

      // Якщо потрібно видалити існуюче зображення
      if (event.removeExistingImage && imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await _storageRepository.deleteRecipeImage(imageUrl);
          imageUrl = null;
        } catch (e) {
          // Продовжуємо навіть якщо видалення не вдалося
          print('Помилка видалення старого зображення: $e');
        }
      }

      // Якщо є нове зображення, завантажуємо його
      if (event.newImageFile != null) {
        try {
          // Спочатку видаляємо старе зображення, якщо воно є
          if (imageUrl != null && imageUrl.isNotEmpty) {
            try {
              await _storageRepository.deleteRecipeImage(imageUrl);
            } catch (e) {
              print('Помилка видалення старого зображення: $e');
            }
          }

          // Завантажуємо нове зображення
          imageUrl = await _storageRepository.uploadRecipeImage(
            event.newImageFile!,
            event.recipe.id,
          );
        } catch (e) {
          emit(RecipeUpdateErrorState('Помилка завантаження зображення: ${e.toString()}'));
          return;
        }
      }

      // Оновлюємо рецепт з новими даними
      final updatedRecipe = event.recipe.copyWith(
        imageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );

      // Зберігаємо оновлений рецепт у Firestore
      await _recipesRepository.updateRecipe(updatedRecipe);

      emit(RecipeUpdateSuccessState(updatedRecipe.id));
    } catch (e) {
      emit(RecipeUpdateErrorState('Помилка оновлення рецепту: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateRecipeReset(
    UpdateRecipeResetEvent event,
    Emitter<UpdateRecipeState> emit,
  ) async {
    emit(UpdateRecipeInitialState());
  }
}
