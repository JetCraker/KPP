abstract class AppStrings {
  // Загальні
  static const String appTitle = 'CookBook Pro';
  static const String appSubtitle = 'Ваша кулінарна колекція';

  // Екран входу
  static const String loginTitle = 'Вхід';
  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Пароль';
  static const String rememberMe = 'Запам\'ятати мене';
  static const String forgotPassword = 'Забули пароль?';
  static const String loginButton = 'Увійти';
  static const String noAccount = 'Немає акаунту? ';
  static const String signUpLink = 'Зареєструватися';
  static const String orDivider = 'або';
  static const String googleButton = 'Google';
  static const String appleButton = 'Apple';

  // Екран реєстрації
  static const String registerTitle = 'Реєстрація';
  static const String createAccount = 'Створіть свій акаунт';
  static const String firstNameLabel = 'Ім\'я';
  static const String lastNameLabel = 'Прізвище';
  static const String confirmPasswordLabel = 'Підтвердження пароля';
  static const String acceptTerms = 'Я погоджуюся з Умовами використання';
  static const String registerButton = 'Зареєструватися';
  static const String haveAccount = 'Вже є акаунт? ';
  static const String loginLink = 'Увійти';

  // Головний екран
  static const String welcomeUser = 'Вітаємо';
  static const String cookingSomething = 'Час готувати щось смачне';
  static const String searchHint = 'Пошук рецептів, інгредієнтів...';
  static const String allCategory = '📚 Всі';
  static const String breakfastCategory = '🍳 Сніданки';
  static const String lunchCategory = '🍽️ Обіди';
  static const String dinnerCategory = '🌙 Вечері';
  static const String dessertCategory = '🍰 Десерти';
  static const String recipesCount = 'Рецептів';
  static const String favoritesCount = 'Улюблених';
  static const String shoppingListCount = 'У списку';
  static const String detailsButton = 'Деталі →';

  // Навігація
  static const String homeNav = 'Головна';
  static const String searchNav = 'Пошук';
  static const String addNav = 'Додати';
  static const String favoritesNav = 'Улюблені';
  static const String profileNav = 'Профіль';

  // Валідація
  static const String requiredField = 'Це поле обов\'язкове';
  static const String invalidEmail = 'Невірний формат email';
  static const String passwordTooShort = 'Пароль має бути мінімум 6 символів';
  static const String passwordsNotMatch = 'Паролі не співпадають';
  static const String nameMinLength = 'Ім\'я має містити мінімум 2 символи';
  static const String acceptTermsRequired = 'Ви маєте погодитися з умовами';

  // Повідомлення
  static const String loginSuccess = 'Успішний вхід!';
  static const String registerSuccess = 'Реєстрація успішна! Перевірте email.';
  static const String passwordResetSent = 'Лист для відновлення надіслано на email';
  static const String logoutSuccess = 'Ви вийшли з акаунту';

  const AppStrings._();
}