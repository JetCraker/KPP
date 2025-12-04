# Bitrise CI/CD Setup для CookBook Pro

## 📋 Передумови

1. Аккаунт на [Bitrise.io](https://bitrise.io)
2. Firebase проєкт з увімкненою Firebase App Distribution
3. Firebase CLI token

## 🔧 Налаштування Bitrise

### 1. Створення проєкту на Bitrise

1. Увійдіть на bitrise.io
2. Натисніть **"Add new app"**
3. Оберіть **GitHub** як джерело
4. Виберіть репозиторій **JetCraker/KPP**
5. Bitrise автоматично виявить Flutter проєкт
6. Завершіть налаштування

### 2. Налаштування Environment Variables (Secrets)

Перейдіть до **Workflow → Secrets** і додайте:

#### Firebase Configuration
```
FIREBASE_TOKEN=<ваш_firebase_token>
FIREBASE_APP_ID_ANDROID=1:86476150805:android:2a8f3ee4551f2d13e9561c
```

**Як отримати FIREBASE_TOKEN:**
```bash
# Встановіть Firebase CLI
npm install -g firebase-tools

# Залогіньтесь
firebase login

# Отримайте token
firebase login:ci
```

#### Development Environment
```
DEV_API_URL=https://dev.api.example.com
DEV_FIREBASE_API_KEY=dev_key
```

#### Staging Environment
```
STAGING_API_URL=https://staging.api.example.com
STAGING_FIREBASE_API_KEY=staging_key
```

#### Production Environment
```
PROD_API_URL=https://prod.api.example.com
PROD_FIREBASE_API_KEY=prod_key
```

### 3. Workflow Configuration

`bitrise.yml` вже налаштований з трьома workflows:
- **android_dev** - DEV builds (branch: main)
- **android_staging** - STAGING builds (branch: staging)
- **android_prod** - PRODUCTION builds (branch: production)

## ⚠️ КРИТИЧНО: Google Sign-In на Bitrise

### Проблема
Google Sign-In **НЕ ПРАЦЮВАТИМЕ** на Bitrise за замовчуванням, бо:
- Bitrise використовує стандартний debug keystore
- SHA-1 fingerprint відрізняється від локального
- Firebase не знає про SHA-1 від Bitrise

### Рішення

#### Крок 1: Отримати SHA-1 з Bitrise

1. Запустіть будь-який build на Bitrise
2. У логах знайдіть секцію **"Get Debug SHA-1"**
3. Скопіюйте SHA-1 fingerprint (буде виглядати як: `A1:B2:C3:...`)

Приклад з логу:
```
════════════════════════════════════════════════════
⚠️  IMPORTANT: Add this SHA-1 to Firebase Console
════════════════════════════════════════════════════

SHA-1:   A1:B2:C3:D4:E5:F6:G7:H8:I9:J0:K1:L2:M3:N4:O5:P6:Q7:R8:S9:T0
SHA-256: ...

📍 Where to add:
   Firebase Console → Project Settings → Your App
   → Add Fingerprint → Paste SHA-1
════════════════════════════════════════════════════
```

#### Крок 2: Додати SHA-1 до Firebase Console

1. Відкрийте [Firebase Console](https://console.firebase.google.com)
2. Оберіть ваш проєкт **cooking-book-2b35e**
3. Перейдіть до **Project Settings** (іконка шестерні)
4. Прокрутіть до секції **Your apps**
5. Знайдіть Android додаток з package name `com.example.cooking_book`
6. Натисніть **"Add fingerprint"**
7. Вставте SHA-1 з Bitrise
8. Натисніть **"Save"**

#### Крок 3: Оновити google-services.json (опціонально)

Firebase автоматично оновить конфігурацію. Але для гарантії:

1. У Firebase Console → Project Settings
2. Завантажте новий `google-services.json`
3. Замініть файл в `android/app/google-services.json`
4. Зробіть commit і push

```bash
git add android/app/google-services.json
git commit -m "Update google-services.json with Bitrise SHA-1"
git push
```

### Альтернативне рішення: Release Keystore

Для production builds використовуйте власний release keystore:

1. Створіть release keystore локально:
```bash
keytool -genkey -v -keystore release.keystore -alias cooking_book -keyalg RSA -keysize 2048 -validity 10000
```

2. Отримайте SHA-1:
```bash
keytool -list -v -keystore release.keystore -alias cooking_book
```

3. Додайте SHA-1 до Firebase Console
4. Завантажте keystore на Bitrise (Workflow → Code Signing)

## 🚀 Запуск Builds

### Автоматичний запуск (через Git)

```bash
# DEV build
git push origin main

# STAGING build
git checkout -b staging
git push origin staging

# PRODUCTION build
git checkout -b production
git push origin production
```

### Ручний запуск

1. Відкрийте Bitrise Dashboard
2. Оберіть проєкт
3. Натисніть **"Start/Schedule a build"**
4. Оберіть workflow: `android_dev`, `android_staging`, або `android_prod`
5. Натисніть **"Start build"**

## 📦 Artifacts

Після успішного build-у, APK файли будуть доступні:

1. **Bitrise Artifacts** - завантажте з Bitrise Dashboard
2. **Firebase App Distribution** - автоматично розіслано тестерам в групі "testers"

Назви файлів:
- `CookingBook-DEV.apk` (debug build)
- `CookingBook-STAGING.apk` (release build)
- `CookingBook-PROD.apk` (release build)

## 🧪 Firebase App Distribution

### Додати тестерів

1. Перейдіть до [Firebase Console](https://console.firebase.google.com)
2. Оберіть проєкт
3. **App Distribution** → **Testers & Groups**
4. Створіть групу **"testers"** (якщо не існує)
5. Додайте email адреси тестерів

### Тестери отримають:

1. Email з посиланням на завантаження
2. Notification через Firebase App Distribution app
3. Release notes з інформацією про build

## ❗ Troubleshooting

### Google Sign-In не працює

✅ **Перевірте:**
1. SHA-1 доданий до Firebase Console
2. `google-services.json` оновлено
3. Package name збігається: `com.example.cooking_book`
4. Google Sign-In увімкнений в Firebase Authentication

### Build не запускається

✅ **Перевірте:**
1. Усі Secrets додані в Bitrise
2. `bitrise.yml` в корені проєкту
3. Branch name відповідає trigger-у

### Firebase upload failed

✅ **Перевірте:**
1. `FIREBASE_TOKEN` валідний
2. `FIREBASE_APP_ID_ANDROID` правильний
3. Група "testers" створена в Firebase Console

## 📚 Корисні посилання

- [Bitrise Documentation](https://devcenter.bitrise.io/)
- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution)
- [Flutter CI/CD Best Practices](https://docs.flutter.dev/deployment/cd)
- [SHA-1 Fingerprint Guide](https://developers.google.com/android/guides/client-auth)

## 🎯 Наступні кроки

1. ✅ Додайте всі Secrets в Bitrise
2. ✅ Зробіть перший build
3. ✅ Скопіюйте SHA-1 з логів
4. ✅ Додайте SHA-1 до Firebase Console
5. ✅ Додайте тестерів в Firebase App Distribution
6. ✅ Зробіть новий build для тестування Google Sign-In
