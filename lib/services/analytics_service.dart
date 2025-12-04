import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // Singleton pattern
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics get analytics => _analytics;

  FirebaseCrashlytics get crashlytics => _crashlytics;

  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
    await _crashlytics.setUserIdentifier(userId);
  }

  Future<void> setUserRole(String role) async {
    await _analytics.setUserProperty(name: 'user_role', value: role);
    await _crashlytics.setCustomKey('user_role', role);
  }

  Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
    await _crashlytics.setCustomKey(name, value);
  }

  Future<void> logLogin({
    required String method,
    String? userId,
  }) async {
    await _analytics.logLogin(loginMethod: method);
    if (userId != null) {
      await setUserId(userId);
    }
  }

  Future<void> logSignUp({
    required String method,
    String? userId,
  }) async {
    await _analytics.logSignUp(signUpMethod: method);
    if (userId != null) {
      await setUserId(userId);
    }
  }

  Future<void> logAdminLogin({
    required String adminId,
    String? loginMethod,
  }) async {
    print('📊 Analytics: Sending admin_login event');
    print('   - admin_id: $adminId');
    print('   - login_method: $loginMethod');
    
    await _analytics.logEvent(
      name: 'admin_login',
      parameters: {
        'admin_id': adminId,
        'login_time': DateTime.now().toIso8601String(),
        'login_method': loginMethod ?? 'unknown',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );

    await setUserRole('admin');
    await setUserId(adminId);

    await _crashlytics.log('Admin login: $adminId');
    print('✅ admin_login event sent successfully!');
  }

  Future<void> logAdminLogout({required String adminId}) async {
    await _analytics.logEvent(
      name: 'admin_logout',
      parameters: {
        'admin_id': adminId,
        'logout_time': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logRecipeView({
    required String recipeId,
    required String recipeName,
    String? category,
  }) async {
    await _analytics.logEvent(
      name: 'recipe_view',
      parameters: {
        'recipe_id': recipeId,
        'recipe_name': recipeName,
        'category': category ?? 'uncategorized',
        'view_time': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logRecipeCreate({
    required String recipeId,
    required String recipeName,
    String? category,
  }) async {
    await _analytics.logEvent(
      name: 'recipe_create',
      parameters: {
        'recipe_id': recipeId,
        'recipe_name': recipeName,
        'category': category ?? 'uncategorized',
        'create_time': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logRecipeEdit({
    required String recipeId,
    required String recipeName,
  }) async {
    await _analytics.logEvent(
      name: 'recipe_edit',
      parameters: {
        'recipe_id': recipeId,
        'recipe_name': recipeName,
        'edit_time': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logRecipeDelete({
    required String recipeId,
    required String recipeName,
  }) async {
    await _analytics.logEvent(
      name: 'recipe_delete',
      parameters: {
        'recipe_id': recipeId,
        'recipe_name': recipeName,
        'delete_time': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logRecipeSearch({
    required String searchTerm,
    int? resultsCount,
  }) async {
    await _analytics.logSearch(
      searchTerm: searchTerm,
    );

    if (resultsCount != null) {
      await _analytics.logEvent(
        name: 'recipe_search_results',
        parameters: {
          'search_term': searchTerm,
          'results_count': resultsCount,
        },
      );
    }
  }


  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }



  /// non-fatal
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  Future<void> recordException(
    dynamic exception, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (context != null) {
      await _crashlytics.log(context);
    }

    if (additionalInfo != null) {
      for (var entry in additionalInfo.entries) {
        await _crashlytics.setCustomKey(entry.key, entry.value);
      }
    }

    await _crashlytics.recordError(
      exception,
      stackTrace ?? StackTrace.current,
      fatal: false,
    );
  }

  Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  Future<void> setCrashlyticsKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  Future<void> sendUnsentReports() async {
    await _crashlytics.sendUnsentReports();
  }

  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }

  Future<void> logCustomEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: parameters?.map((key, value) => MapEntry(key, value as Object)),
    );
  }
}
