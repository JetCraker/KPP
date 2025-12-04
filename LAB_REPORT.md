# ЗВІТ ПРО ВИКОНАННЯ ЛАБОРАТОРНОЇ РОБОТИ
## Інтеграція Firebase Firestore Database та Firebase Storage

---

## 1. ПІДКЛЮЧЕННЯ FIRESTORE DATABASE

### 1.1. Створені колекції та їх структура

#### Колекція: `recipes` (Рецепти)

**Опис:** Основна колекція для зберігання рецептів користувачів.

**Структура документу:**

| Поле | Тип даних | Опис | Обов'язкове |
|------|-----------|------|-------------|
| `id` | string | Унікальний ідентифікатор документа (auto-generated) | ✅ |
| `name` | string | Назва рецепту | ✅ |
| `category` | string | Категорія рецепту (Сніданки, Перші страви, Основні страви, Салати, Десерти) | ✅ |
| `time` | string | Час приготування (формат: "90 хв", "2 год") | ✅ |
| `calories` | number | Калорійність на порцію | ✅ |
| `rating` | number | Рейтинг рецепту (0.0 - 5.0) | ✅ |
| `emoji` | string | Емодзі для візуального представлення | ✅ |
| `description` | string | Детальний опис рецепту | ❌ |
| `ingredients` | array<string> | Список інгредієнтів | ✅ |
| `steps` | array<string> | Покрокові інструкції приготування | ✅ |
| `difficulty` | string | Рівень складності (Легка, Середня, Складна) | ✅ |
| `servings` | number | Кількість порцій | ✅ |
| `authorId` | string | UID автора з Firebase Authentication | ✅ |
| `authorName` | string | Ім'я автора | ✅ |
| `imageUrl` | string | URL зображення в Firebase Storage | ❌ |
| `createdAt` | timestamp | Дата та час створення | ✅ |
| `updatedAt` | timestamp | Дата та час останнього оновлення | ✅ |

**Приклад документу:**
```json
{
  "id": "abc123def456",
  "name": "Борщ український",
  "category": "Перші страви",
  "time": "90 хв",
  "calories": 320,
  "rating": 4.8,
  "emoji": "🥣",
  "description": "Класичний український борщ з м'ясом, буряком та капустою.",
  "ingredients": [
    "Яловичина - 500 г",
    "Буряк - 2 шт",
    "Капуста - 300 г",
    "Картопля - 3 шт"
  ],
  "steps": [
    "Відваріть м'ясо до готовності",
    "Натріть буряк на тертці",
    "Додайте овочі до бульйону"
  ],
  "difficulty": "Середня",
  "servings": 6,
  "authorId": "user123abc",
  "authorName": "Іван Петренко",
  "imageUrl": "https://firebasestorage.googleapis.com/...",
  "createdAt": "2025-11-26T10:30:00Z",
  "updatedAt": "2025-11-26T10:30:00Z"
}
```

---

## 2. НАЛАШТУВАННЯ ПРАВИЛ ДОСТУПУ

### 2.1. Firestore Security Rules

**Файл:** `firestore.rules`

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Функція для перевірки авторизації
    function isSignedIn() {
      return request.auth != null;
    }
    
    // Функція для перевірки, чи є користувач автором
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    // Правила для колекції recipes
    match /recipes/{recipeId} {
      // Читати можуть всі авторизовані користувачі
      allow read: if isSignedIn();
      
      // Створювати можуть тільки авторизовані користувачі
      // authorId має співпадати з UID користувача
      allow create: if isSignedIn() 
                    && request.resource.data.authorId == request.auth.uid
                    && request.resource.data.keys().hasAll([
                      'name', 'category', 'time', 'calories', 
                      'rating', 'emoji', 'authorId', 'authorName'
                    ]);
      
      // Оновлювати та видаляти може тільки автор рецепту
      allow update, delete: if isOwner(resource.data.authorId);
    }
  }
}
```

**Пояснення правил:**
- ✅ **Перегляд:** Всі авторизовані користувачі можуть переглядати рецепти
- ✅ **Створення:** Користувачі можуть створювати рецепти тільки від свого імені
- ✅ **Редагування:** Тільки автор може редагувати свій рецепт
- ✅ **Видалення:** Тільки автор може видалити свій рецепт

---

## 3. СТВОРЕНІ РЕПОЗИТОРІЇ

### 3.1. RecipesRepository

**Файл:** `lib/repositories/recipes_repository.dart`

**Інтерфейс:**
```dart
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
```

**Реалізація:**
```dart
class FirebaseRecipesRepository implements RecipesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  @override
  Stream<List<Recipe>> getRecipes() {
    return _firestore
        .collection('recipes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Recipe.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
  
  @override
  Future<String> addRecipe(Recipe recipe) async {
    final docRef = await _firestore.collection('recipes').add({
      ...recipe.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    await _analytics.logEvent(
      name: 'recipe_created',
      parameters: {'recipe_id': docRef.id},
    );
    
    return docRef.id;
  }
  
  // ... інші методи
}
```

**Ключові особливості:**
- ✅ Використання Stream для реалтайм-оновлень
- ✅ Автоматичне встановлення timestamp через FieldValue.serverTimestamp()
- ✅ Інтеграція з Firebase Analytics
- ✅ Обробка помилок з детальними повідомленнями

### 3.2. StorageRepository

**Файл:** `lib/repositories/storage_repository.dart`

**Інтерфейс:**
```dart
abstract class StorageRepository {
  Future<String> uploadRecipeImage(File imageFile, String recipeId);
  Future<void> deleteRecipeImage(String imageUrl);
  Future<String> getImageUrl(String imagePath);
}
```

**Реалізація:**
```dart
class FirebaseStorageRepository implements StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  @override
  Future<String> uploadRecipeImage(File imageFile, String recipeId) async {
    final fileName = '${recipeId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filePath = 'recipe_images/$fileName';
    
    final ref = _storage.ref().child(filePath);
    final uploadTask = ref.putFile(imageFile, SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'recipeId': recipeId},
    ));
    
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
  
  // ... інші методи
}
```

**Ключові особливості:**
- ✅ Унікальні назви файлів з timestamp
- ✅ Метадані для кращого управління
- ✅ Автоматичне видалення старих зображень при оновленні

---

## 4. СТВОРЕНІ МОДЕЛІ ДАНИХ

### 4.1. Модель Recipe

**Файл:** `lib/models/recipe.dart`

```dart
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

  // Конструктор, copyWith, toJson, fromJson
}
```

**Особливості:**
- ✅ Підтримка nullable полів для Firebase
- ✅ Методи серіалізації/десеріалізації JSON
- ✅ copyWith для іммутабельних оновлень

---

## 5. МЕНЕДЖЕРИ СТАНУ (BLoC)

### 5.1. RecipesBloc (оновлений)

**Файл:** `lib/bloc/recipes_bloc_updated.dart`

**Події:**
- `RefreshRecipesEvent` - завантаження списку рецептів
- `SearchRecipesEvent` - пошук рецептів
- `FilterByCategoryEvent` - фільтрація за категорією
- `SortRecipesEvent` - сортування
- `DeleteRecipeEvent` - видалення рецепту

**Стани:**
- `RecipesLoadingState` - завантаження даних
- `RecipesDataState` - дані успішно завантажені
- `RecipesErrorState` - помилка завантаження

**Код:**
```dart
class RecipesBloc extends Bloc<RecipesEvent, RecipesState> {
  final RecipesRepository _recipesRepository;
  StreamSubscription<List<Recipe>>? _recipesSubscription;
  
  RecipesBloc({required RecipesRepository recipesRepository})
      : _recipesRepository = recipesRepository,
        super(RecipesDataState(data: [])) {
    on<RefreshRecipesEvent>(_onRefreshRecipesEvent);
    // ... інші обробники
  }
  
  Future<void> _onRefreshRecipesEvent(...) async {
    _recipesSubscription = _recipesRepository.getRecipes().listen(
      (recipes) => add(_RecipesUpdatedEvent(recipes)),
      onError: (error) => add(_RecipesErrorEvent(error.toString())),
    );
  }
}
```

### 5.2. CreateRecipeBloc

**Файл:** `lib/bloc/create_recipe_bloc.dart`

**Події:**
- `CreateRecipeSubmitEvent` - створення нового рецепту

**Стани:**
- `CreateRecipeInitialState` - початковий стан
- `RecipeCreatingState` - процес створення
- `RecipeCreateSuccessState` - успішно створено
- `RecipeCreateErrorState` - помилка створення

**Особливості:**
- ✅ Валідація даних перед збереженням
- ✅ Завантаження зображення перед створенням рецепту
- ✅ Автоматичне додавання authorId та authorName

### 5.3. UpdateRecipeBloc

**Файл:** `lib/bloc/update_recipe_bloc.dart`

**Події:**
- `UpdateRecipeSubmitEvent` - оновлення рецепту

**Стани:**
- `UpdateRecipeInitialState` - початковий стан
- `RecipeUpdatingState` - процес оновлення
- `RecipeUpdateSuccessState` - успішно оновлено
- `RecipeUpdateErrorState` - помилка оновлення

**Особливості:**
- ✅ Видалення старого зображення при завантаженні нового
- ✅ Збереження оригінальних даних при помилці
- ✅ Автоматичне оновлення updatedAt timestamp

---

## 6. ІНТЕГРАЦІЯ FIREBASE STORAGE

### 6.1. Storage Rules

**Файл:** `storage.rules`

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isValidSize() {
      return request.resource.size < 5 * 1024 * 1024; // 5MB
    }
    
    function isImage() {
      return request.resource.contentType.matches('image/.*');
    }
    
    match /recipe_images/{imageId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn() && isImage() && isValidSize();
      allow update, delete: if isSignedIn();
    }
  }
}
```

**Обмеження:**
- ✅ Максимальний розмір файлу: 5MB
- ✅ Тільки формати зображень
- ✅ Тільки авторизовані користувачі

### 6.2. Структура зберігання

```
gs://your-project.appspot.com/
└── recipe_images/
    ├── recipeId1_1732617600000.jpg
    ├── recipeId2_1732617700000.jpg
    └── ...
```

**Особливості:**
- ✅ Унікальні назви з timestamp
- ✅ Організація в окремій папці
- ✅ Метадані для відстеження власника

---

## 7. UI КОМПОНЕНТИ

### 7.1. CreateEditRecipeScreen

**Файл:** `lib/screens/create_edit_recipe_screen.dart`

**Функціональність:**
- ✅ Форма створення/редагування рецепту
- ✅ Вибір зображення з галереї
- ✅ Валідація всіх полів
- ✅ Попередній перегляд зображення
- ✅ Індикатор завантаження
- ✅ Обробка помилок

**Компоненти форми:**
- Текстові поля (назва, опис, час, калорії)
- Dropdown меню (категорія, складність)
- Багаторядкові поля (інгредієнти, кроки)
- ImagePicker для зображень

### 7.2. Оновлений HomeScreen

**Інтеграція:**
- ✅ Навігація до екрану створення рецепту
- ✅ Передача BLoC providers
- ✅ Обробка результату створення

---

## 8. ДОДАНІ ЗАЛЕЖНОСТІ

**pubspec.yaml:**
```yaml
dependencies:
  # Firebase
  firebase_core: ^3.8.1
  firebase_analytics: ^11.3.6
  firebase_crashlytics: ^4.1.6
  firebase_auth: ^5.3.3
  firebase_storage: ^12.3.6    # НОВИЙ
  cloud_firestore: ^5.4.5       # НОВИЙ
  
  # State Management
  flutter_bloc: ^8.1.6
  
  # Image Picker
  image_picker: ^1.1.2          # НОВИЙ
```

---

## 9. АРХІТЕКТУРА ДОДАТКУ

```
lib/
├── models/
│   └── recipe.dart                    # Модель Recipe з Firebase полями
├── repositories/
│   ├── auth_repository.dart
│   ├── recipes_repository.dart        # НОВИЙ - Firestore репозиторій
│   └── storage_repository.dart        # НОВИЙ - Storage репозиторій
├── bloc/
│   ├── recipes_bloc_updated.dart      # Оновлений для Firestore
│   ├── create_recipe_bloc.dart        # НОВИЙ
│   ├── update_recipe_bloc.dart        # НОВИЙ
│   ├── recipes_event.dart
│   └── recipes_state.dart
├── screens/
│   ├── home_screen.dart               # Оновлений
│   ├── recipes_list_screen.dart
│   ├── recipe_detail_screen.dart
│   └── create_edit_recipe_screen.dart # НОВИЙ
└── main.dart                          # Оновлений для BLoC providers
```

---

## 10. ТЕСТУВАННЯ ТА ВЕРИФІКАЦІЯ

### 10.1. Перевірка Firestore
- ✅ Створення документів
- ✅ Читання документів
- ✅ Оновлення документів
- ✅ Видалення документів
- ✅ Реалтайм оновлення через Stream
- ✅ Правила безпеки працюють коректно

### 10.2. Перевірка Storage
- ✅ Завантаження зображень
- ✅ Видалення зображень
- ✅ Отримання download URL
- ✅ Обмеження розміру працює
- ✅ Фільтр типів файлів працює

### 10.3. Перевірка BLoC
- ✅ Створення рецепту з зображенням
- ✅ Оновлення рецепту
- ✅ Видалення рецепту
- ✅ Обробка помилок
- ✅ Стани правильно змінюються

---

## ВИСНОВКИ

✅ **Успішно виконано всі пункти завдання:**

1. ✅ Підключено Firestore Database
2. ✅ Створено колекцію `recipes` з детальною структурою
3. ✅ Налаштовано правила доступу для безпеки даних
4. ✅ Створено репозиторії для Firestore та Storage
5. ✅ Реалізовано моделі даних з серіалізацією
6. ✅ Створено BLoC менеджери стану (Create, Update)
7. ✅ Інтегровано Firebase Storage для зображень
8. ✅ Створено UI для створення/редагування рецептів
9. ✅ Налаштовано Storage Rules з обмеженнями
10. ✅ Підготовлено детальну інструкцію для Firebase Console

**Додаток готовий до використання з повнофункціональною інтеграцією Firebase!**
