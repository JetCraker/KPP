import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Екран для тестування Firebase Analytics та Crashlytics
/// 
/// Цей екран дозволяє:
/// - Відправляти тестові краш-репорти
/// - Логувати кастомні події
/// - Встановлювати параметри користувача
class AnalyticsTestScreen extends StatefulWidget {
  const AnalyticsTestScreen({super.key});

  @override
  State<AnalyticsTestScreen> createState() => _AnalyticsTestScreenState();
}

class _AnalyticsTestScreenState extends State<AnalyticsTestScreen> {
  final _analytics = FirebaseAnalytics.instance;
  final _crashlytics = FirebaseCrashlytics.instance;
  
  bool _isAdminMode = false;

  @override
  void initState() {
    super.initState();
    // Логуємо відкриття екрану тестування
    _analytics.logScreenView(screenName: 'AnalyticsTestScreen');
  }

  /// Відправити тестовий краш (фатальна помилка)
  Future<void> _sendTestCrash() async {
    try {
      // Примусово викликаємо помилку для тесту
      throw Exception('Це тестова помилка для Firebase Crashlytics');
    } catch (error, stackTrace) {
      // Записуємо помилку в Crashlytics
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: 'Тестовий краш викликаний користувачем',
        fatal: false, // false = non-fatal, true = fatal
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Краш-репорт відправлено в Firebase!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Відправити фатальний краш (призведе до закриття застосунку)
  Future<void> _sendFatalCrash() async {
    // УВАГА: Це призведе до краху застосунку!
    await _crashlytics.recordError(
      Exception('Фатальна тестова помилка'),
      StackTrace.current,
      reason: 'Фатальний тестовий краш',
      fatal: true,
    );
    
    // Примусовий краш
    throw Exception('Фатальна тестова помилка');
  }

  /// Логування кастомної події - вхід адміна
  Future<void> _logAdminLoginEvent() async {
    // Перемикаємо режим адміна
    setState(() {
      _isAdminMode = !_isAdminMode;
    });

    if (_isAdminMode) {
      // Логуємо подію входу адміна з параметрами
      await _analytics.logEvent(
        name: 'admin_login',
        parameters: {
          'admin_id': 'admin_12345',
          'login_time': DateTime.now().toIso8601String(),
          'login_method': 'manual_test',
          'device_type': 'mobile',
        },
      );

      // Встановлюємо властивість користувача
      await _analytics.setUserProperty(
        name: 'user_role',
        value: 'admin',
      );

      // Встановлюємо ID користувача
      await _analytics.setUserId(id: 'admin_12345');

      // Також записуємо в Crashlytics для кращого відстеження помилок
      await _crashlytics.setUserIdentifier('admin_12345');
      await _crashlytics.setCustomKey('user_role', 'admin');
      await _crashlytics.setCustomKey('is_admin', true);
    } else {
      // Виходимо з режиму адміна
      await _analytics.setUserProperty(
        name: 'user_role',
        value: 'user',
      );

      await _analytics.logEvent(
        name: 'admin_logout',
        parameters: {
          'admin_id': 'admin_12345',
          'logout_time': DateTime.now().toIso8601String(),
        },
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isAdminMode
                ? 'Режим адміна АКТИВОВАНО ✓'
                : 'Режим адміна ДЕАКТИВОВАНО',
          ),
          backgroundColor: _isAdminMode ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Логування кастомної події - перегляд рецепту
  Future<void> _logRecipeViewEvent() async {
    await _analytics.logEvent(
      name: 'recipe_view',
      parameters: {
        'recipe_id': 'recipe_001',
        'recipe_name': 'Борщ український',
        'category': 'супи',
        'view_time': DateTime.now().toIso8601String(),
      },
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Подія перегляду рецепту відправлена!'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тестування Analytics'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Статус режиму адміна
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isAdminMode ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isAdminMode ? Colors.green : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isAdminMode ? Icons.admin_panel_settings : Icons.person,
                  color: _isAdminMode ? Colors.green : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isAdminMode ? 'Режим адміна АКТИВНИЙ' : 'Звичайний користувач',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isAdminMode ? Colors.green.shade800 : Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        _isAdminMode
                            ? 'Всі дії логуються як адмін'
                            : 'Активуйте режим адміна для тестування',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Секція Analytics
          _buildSectionTitle('Firebase Analytics', Icons.analytics, Colors.blue),
          const SizedBox(height: 12),

          _buildTestButton(
            title: '👤 ${_isAdminMode ? "Вийти з режиму адміна" : "Увійти як адмін"}',
            description: 'Логує кастомну подію admin_login з параметрами',
            color: _isAdminMode ? Colors.orange : Colors.green,
            onPressed: _logAdminLoginEvent,
            icon: Icons.admin_panel_settings,
          ),

          const SizedBox(height: 8),

          _buildTestButton(
            title: '📖 Переглянути рецепт',
            description: 'Логує подію recipe_view з деталями рецепту',
            color: Colors.blue,
            onPressed: _logRecipeViewEvent,
            icon: Icons.visibility,
          ),

          const SizedBox(height: 24),

          // Секція Crashlytics
          _buildSectionTitle('Firebase Crashlytics', Icons.bug_report, Colors.red),
          const SizedBox(height: 12),

          _buildTestButton(
            title: '⚠️ Відправити Non-Fatal краш',
            description: 'Відправляє помилку без закриття додатку',
            color: Colors.orange,
            onPressed: _sendTestCrash,
            icon: Icons.warning_amber,
          ),

          const SizedBox(height: 8),

          _buildTestButton(
            title: '💥 Відправити Fatal краш',
            description: 'УВАГА: Закриє додаток! Тільки для тестування',
            color: Colors.red,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('⚠️ Попередження'),
                  content: const Text(
                    'Це призведе до закриття додатку!\n\n'
                    'Використовуйте тільки для тестування Crashlytics.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Скасувати'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _sendFatalCrash();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Виконати'),
                    ),
                  ],
                ),
              );
            },
            icon: Icons.dangerous,
          ),

        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTestButton({
    required String title,
    required String description,
    required Color color,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
