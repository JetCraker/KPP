import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/auth_repository.dart';
import '../constants/app_strings.dart';
import 'login_screen.dart';
import 'recipes_list_screen.dart';
import 'create_edit_recipe_screen.dart';
import '../bloc/create_recipe_bloc.dart';
import '../bloc/update_recipe_bloc.dart';
import '../repositories/recipes_repository.dart';
import '../repositories/storage_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _analytics = FirebaseAnalytics.instance;
  final _authRepository = AuthRepository();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _analytics.logScreenView(screenName: 'HomeScreen');
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Вихід'),
        content: const Text('Ви дійсно хочете вийти з акаунту?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Вийти'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authRepository.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.logoutSuccess),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  void _handleAddRecipe() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => CreateRecipeBloc(
                recipesRepository: context.read<RecipesRepository>(),
                storageRepository: context.read<StorageRepository>(),
              ),
            ),
            BlocProvider(
              create: (context) => UpdateRecipeBloc(
                recipesRepository: context.read<RecipesRepository>(),
                storageRepository: context.read<StorageRepository>(),
              ),
            ),
          ],
          child: const CreateEditRecipeScreen(),
        ),
      ),
    );
  }

  String _getUserInitials() {
    final user = _authRepository.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      final parts = user.displayName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }
    return user?.email?[0].toUpperCase() ?? 'У';
  }

  @override
  Widget build(BuildContext context) {
    // Список екранів для навігації
    final List<Widget> screens = [
      const RecipesListScreen(),
      const Center(child: Text('Пошук')),
      const Center(child: Text('Додати рецепт')), // Замінено нижче на callback
      const Center(child: Text('Улюблені')),
      const Center(child: Text('Налаштування')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CookBook Pro'),
        backgroundColor: Colors.orange.shade500,
        foregroundColor: Colors.white,
        actions: [
          GestureDetector(
            onTap: _handleLogout,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _getUserInitials(),
                  style: TextStyle(
                    color: Colors.orange.shade500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _currentIndex == 2 
          ? const Center(child: Text('Натисніть кнопку "+" для додавання рецепту'))
          : screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            // При натисканні на кнопку "Додати" відкриваємо екран створення
            _handleAddRecipe();
          } else {
            setState(() {
              _currentIndex = index;
            });

            _analytics.logEvent(
              name: 'tab_change',
              parameters: {'tab_index': index},
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange.shade500,
        unselectedItemColor: Colors.grey.shade400,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: AppStrings.homeNav,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: AppStrings.searchNav,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 32),
            label: AppStrings.addNav,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: AppStrings.favoritesNav,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: AppStrings.profileNav,
          ),
        ],
      ),
    );
  }
}