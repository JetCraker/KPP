import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import '../bloc/recipes_bloc_updated.dart';
import '../bloc/recipes_event.dart';
import '../repositories/recipes_repository.dart';
import '../repositories/storage_repository.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.orange.shade500,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.recipe.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
              background: widget.recipe.imageUrl != null && widget.recipe.imageUrl!.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.recipe.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.orange.shade400,
                                    Colors.red.shade400,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  widget.recipe.emoji,
                                  style: const TextStyle(fontSize: 120),
                                ),
                              ),
                            );
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.orange.shade400,
                            Colors.red.shade400,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.recipe.emoji,
                          style: const TextStyle(fontSize: 120),
                        ),
                      ),
                    ),
            ),
            actions: [
              // Кнопка видалення (тільки для автора)
              if (_isCurrentUserAuthor())
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _showDeleteConfirmation,
                ),
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isFavorite = !_isFavorite;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isFavorite
                            ? 'Додано до улюблених'
                            : 'Видалено з улюблених',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        Icons.access_time,
                        'Час',
                        widget.recipe.time,
                        Colors.blue,
                      ),
                      _buildStatItem(
                        Icons.local_fire_department,
                        'Калорії',
                        '${widget.recipe.calories} ккал',
                        Colors.orange,
                      ),
                      _buildStatItem(
                        Icons.restaurant,
                        'Порцій',
                        '${widget.recipe.servings}',
                        Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      _buildChip(
                        Icons.category,
                        widget.recipe.category,
                        Colors.purple,
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        Icons.bar_chart,
                        widget.recipe.difficulty,
                        _getDifficultyColor(widget.recipe.difficulty),
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        Icons.star,
                        widget.recipe.rating.toString(),
                        Colors.amber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (widget.recipe.authorName != null) ...[
                    Row(
                      children: [
                        Icon(Icons.person, size: 20, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Автор: ${widget.recipe.authorName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (widget.recipe.description.isNotEmpty) ...[
                    const Text(
                      'Опис',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.recipe.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),

          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: Colors.orange.shade500,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.orange.shade500,
                tabs: const [
                  Tab(text: 'Інгредієнти'),
                  Tab(text: 'Приготування'),
                ],
              ),
            ),
          ),

          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildIngredientsTab(),
                _buildStepsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsTab() {
    if (widget.recipe.ingredients.isEmpty) {
      return const Center(
        child: Text('Інгредієнти не вказані'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.recipe.ingredients.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade100,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              widget.recipe.ingredients[index],
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepsTab() {
    if (widget.recipe.steps.isEmpty) {
      return const Center(
        child: Text('Кроки приготування не вказані'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.recipe.steps.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade500,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Крок ${index + 1}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.recipe.steps[index],
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Легка':
        return Colors.green;
      case 'Середня':
        return Colors.orange;
      case 'Складна':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Перевірка, чи поточний користувач є автором рецепту
  bool _isCurrentUserAuthor() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || widget.recipe.authorId == null) {
      return false;
    }
    return currentUser.uid == widget.recipe.authorId;
  }

  /// Показати діалог підтвердження видалення
  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Видалити рецепт?'),
        content: Text('Ви впевнені, що хочете видалити "${widget.recipe.name}"? Цю дію неможливо скасувати.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteRecipe();
    }
  }

  /// Видалити рецепт
  Future<void> _deleteRecipe() async {
    try {
      // Показуємо індикатор завантаження
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Отримуємо репозиторії
      final recipesRepo = context.read<RecipesRepository>();
      final storageRepo = context.read<StorageRepository>();

      // Видаляємо зображення якщо є
      if (widget.recipe.imageUrl != null && widget.recipe.imageUrl!.isNotEmpty) {
        try {
          await storageRepo.deleteRecipeImage(widget.recipe.imageUrl!);
        } catch (e) {
          // Продовжуємо навіть якщо зображення не вдалося видалити
          debugPrint('Помилка видалення зображення: $e');
        }
      }

      // Видаляємо рецепт з Firestore
      await recipesRepo.deleteRecipe(widget.recipe.id);

      // Оновлюємо список рецептів через BLoC
      if (mounted) {
        context.read<RecipesBloc>().add(RefreshRecipesEvent());
      }

      // Закриваємо діалог завантаження
      if (mounted) {
        Navigator.pop(context);
      }

      // Повертаємось на попередній екран
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Рецепт успішно видалено'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Закриваємо діалог завантаження
      if (mounted) {
        Navigator.pop(context);
      }

      // Показуємо помилку
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка видалення: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}