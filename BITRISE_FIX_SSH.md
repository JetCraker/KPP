# ⚠️ Bitrise Build Issues - Fix Guide

## 1. Git Clone Permission Denied (SSH) ✅ ВИРІШЕНО

### Проблема
```
git@github.com: Permission denied (publickey).
fatal: Could not read from remote repository.
```

Bitrise намагається клонувати через SSH, але SSH ключі не налаштовані.

## ✅ Рішення: Перемкнути на HTTPS Clone

### Спосіб 1: Через Bitrise Dashboard (РЕКОМЕНДОВАНО)

1. **Відкрийте Bitrise Dashboard**
   - Перейдіть на https://app.bitrise.io
   - Оберіть ваш проєкт

2. **Settings → General**
   - Знайдіть секцію **"Repository settings"**
   - Клікніть **"Change repository"** або **"Reconnect"**

3. **Змініть SSH на HTTPS**
   
   Замість:
   ```
   git@github.com:JetCraker/KPP.git
   ```
   
   Використайте:
   ```
   https://github.com/JetCraker/KPP.git
   ```

4. **Збережіть зміни**
   - Клікніть **"Save"**
   - Bitrise автоматично перевірить доступ

5. **Запустіть новий build**
   - Start/Schedule a build
   - Оберіть `android_dev` workflow
   - Натисніть "Start build"

### Спосіб 2: Налаштувати SSH ключі (складніше)

Якщо хочете використовувати SSH:

1. **Згенеруйте SSH ключ**
   ```bash
   ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -f bitrise_rsa
   ```

2. **Додайте публічний ключ на GitHub**
   - Скопіюйте вміст `bitrise_rsa.pub`
   - GitHub → Settings → SSH and GPG keys → New SSH key
   - Вставте ключ

3. **Додайте приватний ключ на Bitrise**
   - Bitrise Dashboard → Workflow → Code Signing
   - Upload SSH private key
   - Вставте вміст `bitrise_rsa`

4. **Оновіть bitrise.yml**
   ```yaml
   steps:
   - activate-ssh-key@4:
       run_if: '{{getenv "SSH_RSA_PRIVATE_KEY" | ne ""}}'
   - git-clone@8: {}
   ```

## 🎯 Рекомендація

**Використовуйте Спосіб 1 (HTTPS)** - це простіше і не потребує додаткових налаштувань.

Для публічних репозиторіїв HTTPS clone працює без жодних проблем.

## ✅ Перевірка

Після зміни на HTTPS, build повинен успішно клонувати репозиторій:

```
✓ Git Clone Repository (Succeeded) 3.24 sec
```

Якщо все ще не працює:
1. Перевірте, чи репозиторій публічний
2. Перевірте URL репозиторію в Bitrise Settings
3. Спробуйте видалити і перестворити app на Bitrise

---

## 2. Firebase Authentication Error ✅ ВИРІШЕНО

### Проблема
```
Error: A Not Found error was returned while attempting to retrieve an accesstoken
Could not refresh access token: Request failed with status code 404
Error: Failed to authenticate, have you run firebase login?
```

Firebase CLI намагається використовувати Google Cloud автентифікацію замість токену.

### ✅ Рішення: Додати FIREBASE_TOKEN

1. **Отримайте Firebase CI Token локально:**
   ```bash
   npm install -g firebase-tools
   firebase login:ci
   ```

2. **Скопіюйте token** (він виглядає як: `1//0aBcDeFg...`)

3. **Додайте на Bitrise:**
   - Bitrise Dashboard → Workflow → Secrets
   - Натисніть **"Add new"**
   - Key: `FIREBASE_TOKEN`
   - Value: вставте ваш token
   - ☑️ Mark as "Protected" and "Expose for Pull Requests"
   - Натисніть **"Add"**

4. **Запустіть новий build**

---

## 3. Firebase App Distribution 404 Error ⚠️ ПОТОЧНА ПРОБЛЕМА

### Проблема
```
Error: failed to distribute to testers/groups: 
Request to https://firebaseappdistribution.googleapis.com/.../releases/...:distribute 
had HTTP Error: 404, Requested entity was not found.
```

Firebase App Distribution не налаштовано для вашого Android додатку.

### ✅ Рішення: Увімкнути Firebase App Distribution

#### Крок 1: Увімкніть App Distribution в Firebase Console

1. **Відкрийте Firebase Console**
   - Перейдіть на https://console.firebase.google.com
   - Оберіть проєкт: **cooking-book-2b35e**

2. **Увімкніть App Distribution**
   - У лівому меню знайдіть **"Release & Monitor"**
   - Клікніть **"App Distribution"**
   - Якщо бачите "Get Started" - натисніть його
   - Дочекайтесь активації (може зайняти 1-2 хвилини)

3. **Перевірте, що ваш Android додаток відображається**
   - В App Distribution повинен бути додаток: `com.example.cooking_book`
   - Якщо його немає - додайте вручну

#### Крок 2: Створіть групу тестерів

1. **В App Distribution перейдіть до "Testers & Groups"**
2. **Створіть нову групу:**
   - Натисніть **"Add group"**
   - Назва групи: `testers` (точно так, як в bitrise.yml)
   - Додайте email адреси тестерів
   - Натисніть **"Save"**

3. **Перевірте, що група створена**
   - Група `testers` повинна бути в списку

#### Крок 3: Отримайте правильний App ID

1. **Firebase Console → Project Settings** (⚙️ іконка)
2. **Прокрутіть до "Your apps"**
3. **Знайдіть Android додаток** `com.example.cooking_book`
4. **Скопіюйте App ID** - він виглядає як:
   ```
   1:86476150805:android:2a8f3ee4551f2d13e9561c
   ```

#### Крок 4: Оновіть App ID на Bitrise

1. **Bitrise Dashboard → Workflow → Secrets**
2. **Знайдіть** `FIREBASE_APP_ID_ANDROID`
3. **Оновіть значення:**
   ```
   1:86476150805:android:2a8f3ee4551f2d13e9561c
   ```
4. **Збережіть**

#### Крок 5: Перший upload вручну (опціонально)

Щоб переконатися, що все працює, можна зробити перший upload локально:

```bash
# Build APK
flutter build apk --debug --flavor dev -t lib/main_dev.dart

# Upload до Firebase
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-dev-debug.apk \
  --app 1:86476150805:android:2a8f3ee4551f2d13e9561c \
  --groups "testers" \
  --release-notes "Test upload"
```

Якщо це спрацює - Bitrise теж спрацює.

#### Крок 6: Запустіть новий build на Bitrise

---

## ✅ Checklist для успішного Bitrise build

- [ ] Repository URL змінено на HTTPS
- [ ] `FIREBASE_TOKEN` доданий в Bitrise Secrets
- [ ] Firebase App Distribution увімкнено в Firebase Console
- [ ] Група `testers` створена в Firebase App Distribution
- [ ] `FIREBASE_APP_ID_ANDROID` правильний в Bitrise Secrets
- [ ] Environment variables додані (`DEV_API_URL`, `DEV_FIREBASE_API_KEY`, etc.)

---

## 🆘 Додаткова допомога

### Перевірка Firebase App ID

```bash
# Локально перевірте, чи App ID правильний
firebase apps:list --project cooking-book-2b35e
```

Має показати ваш Android додаток з правильним App ID.

### Debugging Firebase Distribution

Якщо все ще не працює, додайте `--debug` до команди:

```bash
firebase appdistribution:distribute "$ANDROID_APK_PATH" \
  --app "$FIREBASE_APP_ID_ANDROID" \
  --token "$FIREBASE_TOKEN" \
  --groups "testers" \
  --debug
```

Це покаже детальну інформацію про помилку.

### Альтернатива: Bitrise Deploy

Якщо Firebase App Distribution не працює, можна використовувати вбудований Bitrise Artifacts:

1. Artifacts доступні через Bitrise Dashboard
2. Можна поділитися посиланням з тестерами
3. Не потребує Firebase налаштувань

---

## 📚 Корисні посилання

- [Firebase App Distribution Setup](https://firebase.google.com/docs/app-distribution/android/distribute-console)
- [Firebase CLI Token](https://firebase.google.com/docs/cli#cli-ci-systems)
- [Bitrise Git Clone](https://devcenter.bitrise.io/en/steps-and-workflows/introduction-to-steps/git-clone-step.html)

Firebase CLI не може автентифікуватись на Bitrise.

## ✅ Рішення: Додати FIREBASE_TOKEN

### Крок 1: Отримати Firebase Token (локально)

```bash
# Встановіть Firebase CLI
npm install -g firebase-tools

# Залогіньтесь (відкриється браузер)
firebase login

# Отримайте CI token
firebase login:ci
```

Після успішного логіну, ви отримаєте токен:
```
✔  Success! Use this token to login on a CI server:

1//0gABCDEFGHIJKLMNOP...

Example: firebase deploy --token "$FIREBASE_TOKEN"
```

**Скопіюйте цей токен!**

### Крок 2: Додати Token до Bitrise Secrets

1. Відкрийте Bitrise Dashboard → Ваш проєкт
2. Перейдіть до **Workflow → Secrets**
3. Натисніть **"Add new"**
4. Key: `FIREBASE_TOKEN`
5. Value: вставте скопійований токен
6. ✅ **"Protected"** - увімкніть (щоб токен не показувався в логах)
7. Натисніть **"Save"**

### Крок 3: Додати інші обов'язкові Secrets

```
FIREBASE_APP_ID_ANDROID=1:86476150805:android:2a8f3ee4551f2d13e9561c

DEV_API_URL=https://dev.api.example.com
DEV_FIREBASE_API_KEY=dev_key

STAGING_API_URL=https://staging.api.example.com
STAGING_FIREBASE_API_KEY=staging_key

PROD_API_URL=https://prod.api.example.com
PROD_FIREBASE_API_KEY=prod_key
```

### Крок 4: Запустіть новий build

Після додавання всіх Secrets:
1. **Start/Schedule a build**
2. Оберіть workflow: **android_dev**
3. Branch: **main**
4. Натисніть **"Start build"**

### Крок 4: Увімкнути Firebase App Distribution

⚠️ **КРИТИЧНО:** Firebase App Distribution може бути не увімкнений для вашого додатку!

1. Відкрийте [Firebase Console](https://console.firebase.google.com)
2. Оберіть проєкт **cooking-book-2b35e**
3. У лівому меню знайдіть **"Release & Monitor"** → **"App Distribution"**
4. Якщо бачите "Get started" - натисніть його
5. Оберіть ваш Android додаток (`com.example.cooking_book`)
6. Натисніть **"Get started"** або **"Set up App Distribution"**
7. Створіть групу тестерів з назвою **"testers"**:
   - App Distribution → **Testers & Groups**
   - Натисніть **"Add group"**
   - Назва: `testers`
   - Додайте email адреси тестерів
   - Збережіть

### Крок 5: Перевірка App ID

Переконайтесь, що використовується правильний App ID в Bitrise Secrets:

```
FIREBASE_APP_ID_ANDROID=1:86476150805:android:2a8f3ee4551f2d13e9561c
```

**Як знайти правильний App ID:**
1. Firebase Console → Project Settings
2. Прокрутіть до **"Your apps"**
3. Знайдіть Android додаток
4. Скопіюйте **"App ID"** (формат: `1:PROJECT_NUMBER:android:HASH`)

### Крок 6: Запустіть новий build

Після увімкнення App Distribution і додавання всіх Secrets:
1. **Start/Schedule a build**
2. Оберіть workflow: **android_dev**
3. Branch: **main**
4. Натисніть **"Start build"**

### Перевірка успішності

Build має успішно пройти:
```
✓ Firebase App Distribution (DEV) (Succeeded)
  ✅ Successfully uploaded to Firebase App Distribution!
  📧 Testers in 'testers' group will receive notification
```

## ❌ Troubleshooting

### Error: 404, Requested entity was not found

**Причина:** Firebase App Distribution не увімкнений або App ID неправильний.

**Рішення:**
1. Увімкніть App Distribution в Firebase Console (Крок 4)
2. Перевірте правильність `FIREBASE_APP_ID_ANDROID`
3. Переконайтесь, що додаток існує в Firebase Console
4. Створіть групу "testers" в App Distribution

### Error: groups "testers" not found

**Причина:** Група тестерів не створена.

**Рішення:**
1. Firebase Console → App Distribution → Testers & Groups
2. Створіть групу з назвою `testers`
3. Додайте хоча б один email

## 🔒 Важливо про безпеку

- Завжди позначайте `FIREBASE_TOKEN` як **"Protected"**
- Ніколи не commitьте токен в репозиторій
- Токен дійсний до моменту, поки ви не зробите `firebase logout`
- Для production використовуйте Service Account Key (детальніше в BITRISE_SETUP.md)
