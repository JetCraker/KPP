# 🚀 Quick Start: Запуск різних середовищ

## Локальний запуск

### Development (DEV)
```bash
flutter run -t lib/main_dev.dart --flavor dev
```

### Staging (STG)
```bash
flutter run -t lib/main_staging.dart --flavor staging
```

### Production (PROD)
```bash
flutter run -t lib/main_prod.dart --flavor prod
```

## Build APK

### Debug Build (для тестування)
```bash
# DEV
flutter build apk --debug --flavor dev -t lib/main_dev.dart

# STAGING
flutter build apk --debug --flavor staging -t lib/main_staging.dart

# PROD
flutter build apk --debug --flavor prod -t lib/main_prod.dart
```

### Release Build (для production)
```bash
# DEV
flutter build apk --release --flavor dev -t lib/main_dev.dart

# STAGING
flutter build apk --release --flavor staging -t lib/main_staging.dart

# PROD
flutter build apk --release --flavor prod -t lib/main_prod.dart
```

## Environment Variables

Файли `.env.*` вже створені з прикладами. Для production оновіть значення:

**`.env.dev`**
```env
apiUrl=https://dev.api.example.com
firebaseApiKey=dev_key
```

**`.env.staging`**
```env
apiUrl=https://staging.api.example.com
firebaseApiKey=staging_key
```

**`.env.prod`**
```env
apiUrl=https://prod.api.example.com
firebaseApiKey=prod_key
```

## Регенерація env файлів

Якщо змінили `.env.*` файли, запустіть:
```bash
dart run build_runner build --delete-conflicting-outputs
```

## CI/CD (Bitrise)

Детальна інструкція в [BITRISE_SETUP.md](./BITRISE_SETUP.md)

### Автоматичний deploy:
- **Push to `main`** → DEV build
- **Push to `staging`** → STAGING build
- **Push to `production`** → PROD build

## ⚠️ Важливо

### Google Sign-In
Google Authentication працює тільки з правильним SHA-1 fingerprint:

**Локально:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**На Bitrise:**
SHA-1 буде в логах build-у. Додайте його до Firebase Console.

Детальні інструкції в [BITRISE_SETUP.md](./BITRISE_SETUP.md)
