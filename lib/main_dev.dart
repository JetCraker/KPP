import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'bloc/recipes_bloc_updated.dart';
import 'bloc/create_recipe_bloc.dart';
import 'bloc/update_recipe_bloc.dart';
import 'repositories/recipes_repository.dart';
import 'repositories/storage_repository.dart';
import 'env/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  if (kDebugMode) {
    print('🐛 DEV MODE');
    print('📡 API URL: ${EnvDev.apiUrl}');
    print('🔑 Firebase API Key: ${EnvDev.firebaseApiKey}');
  }

  runApp(const MyApp(env: "DEV"));
}

class MyApp extends StatelessWidget {
  final String env;
  
  const MyApp({super.key, required this.env});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
  FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    // Створюємо репозиторії
    final recipesRepository = FirebaseRecipesRepository();
    final storageRepository = FirebaseStorageRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<RecipesRepository>.value(value: recipesRepository),
        RepositoryProvider<StorageRepository>.value(value: storageRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => RecipesBloc(
              recipesRepository: recipesRepository,
            ),
          ),
          BlocProvider(
            create: (context) => CreateRecipeBloc(
              recipesRepository: recipesRepository,
              storageRepository: storageRepository,
            ),
          ),
          BlocProvider(
            create: (context) => UpdateRecipeBloc(
              recipesRepository: recipesRepository,
              storageRepository: storageRepository,
            ),
          ),
        ],
        child: MaterialApp(
          title: 'CookBook Pro [$env]',
          theme: ThemeData(
            primarySwatch: Colors.orange,
            useMaterial3: true,
          ),
          navigatorObservers: [observer],
          home: const LoginScreen(),
        ),
      ),
    );
  }
}
