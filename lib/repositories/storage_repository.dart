import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

abstract class StorageRepository {
  Future<String> uploadRecipeImage(File imageFile, String recipeId);
  
  Future<void> deleteRecipeImage(String imageUrl);

  Future<String> getImageUrl(String imagePath);
}

class FirebaseStorageRepository implements StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  static const String _recipeImagesFolder = 'recipe_images';

  @override
  Future<String> uploadRecipeImage(File imageFile, String recipeId) async {
    try {
      // Створюємо унікальну назву файлу
      final String fileName = '${recipeId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = '$_recipeImagesFolder/$fileName';
      
      // Посилання на файл в Storage
      final Reference ref = _storage.ref().child(filePath);

      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'recipeId': recipeId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      final UploadTask uploadTask = ref.putFile(imageFile, metadata);
      
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      await _analytics.logEvent(
        name: 'image_uploaded',
        parameters: {
          'recipe_id': recipeId,
          'file_path': filePath,
        },
      );
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Помилка завантаження зображення: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteRecipeImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return;
      
      final Reference ref = _storage.refFromURL(imageUrl);
      
      await ref.delete();
      
      await _analytics.logEvent(
        name: 'image_deleted',
        parameters: {
          'image_url': imageUrl,
        },
      );
    } catch (e) {
      if (e.toString().contains('object-not-found')) {
        return;
      }
      throw Exception('Помилка видалення зображення: ${e.toString()}');
    }
  }

  @override
  Future<String> getImageUrl(String imagePath) async {
    try {
      final Reference ref = _storage.ref().child(imagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Помилка отримання URL зображення: ${e.toString()}');
    }
  }
  
  Future<FullMetadata> getImageMetadata(String imagePath) async {
    try {
      final Reference ref = _storage.ref().child(imagePath);
      return await ref.getMetadata();
    } catch (e) {
      throw Exception('Помилка отримання метаданих: ${e.toString()}');
    }
  }

  Future<int> getImageSize(String imagePath) async {
    try {
      final metadata = await getImageMetadata(imagePath);
      return metadata.size ?? 0;
    } catch (e) {
      throw Exception('Помилка отримання розміру файлу: ${e.toString()}');
    }
  }
}
