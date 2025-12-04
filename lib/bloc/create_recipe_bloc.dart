import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import '../repositories/recipes_repository.dart';
import '../repositories/storage_repository.dart';

// Events
abstract class CreateRecipeEvent {}

class CreateRecipeSubmitEvent extends CreateRecipeEvent {
  final Recipe recipe;
  final File? imageFile;

  CreateRecipeSubmitEvent({
    required this.recipe,
    this.imageFile,
  });
}

class CreateRecipeResetEvent extends CreateRecipeEvent {}

// States
abstract class CreateRecipeState {}

class CreateRecipeInitialState extends CreateRecipeState {}

class RecipeCreatingState extends CreateRecipeState {}

class RecipeCreateSuccessState extends CreateRecipeState {
  final String recipeId;

  RecipeCreateSuccessState(this.recipeId);
}

class RecipeCreateErrorState extends CreateRecipeState {
  final String error;

  RecipeCreateErrorState(this.error);
}

// BLoC
class CreateRecipeBloc extends Bloc<CreateRecipeEvent, CreateRecipeState> {
  final RecipesRepository _recipesRepository;
  final StorageRepository _storageRepository;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CreateRecipeBloc({
    required RecipesRepository recipesRepository,
    required StorageRepository storageRepository,
  })  : _recipesRepository = recipesRepository,
        _storageRepository = storageRepository,
        super(CreateRecipeInitialState()) {
    on<CreateRecipeSubmitEvent>(_onCreateRecipeSubmit);
    on<CreateRecipeResetEvent>(_onCreateRecipeReset);
  }

  Future<void> _onCreateRecipeSubmit(
    CreateRecipeSubmitEvent event,
    Emitter<CreateRecipeState> emit,
  ) async {
    emit(RecipeCreatingState());

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        emit(RecipeCreateErrorState('Необхідно увійти в систему'));
        return;
      }

      String? imageUrl;

      if (event.imageFile != null) {
        try {
          final tempId = DateTime.now().millisecondsSinceEpoch.toString();
          imageUrl = await _storageRepository.uploadRecipeImage(
            event.imageFile!,
            tempId,
          );
        } catch (e) {
          emit(RecipeCreateErrorState('Помилка завантаження зображення: ${e.toString()}'));
          return;
        }
      }

      final recipe = event.recipe.copyWith(
        authorId: currentUser.uid,
        authorName: currentUser.displayName ?? currentUser.email ?? 'Користувач',
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final recipeId = await _recipesRepository.addRecipe(recipe);

      emit(RecipeCreateSuccessState(recipeId));
    } catch (e) {
      emit(RecipeCreateErrorState('Помилка створення рецепту: ${e.toString()}'));
    }
  }

  Future<void> _onCreateRecipeReset(
    CreateRecipeResetEvent event,
    Emitter<CreateRecipeState> emit,
  ) async {
    emit(CreateRecipeInitialState());
  }
}
