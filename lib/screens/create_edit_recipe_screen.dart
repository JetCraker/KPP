import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../models/recipe.dart';
import '../bloc/create_recipe_bloc.dart';
import '../bloc/update_recipe_bloc.dart';

class CreateEditRecipeScreen extends StatefulWidget {
  final Recipe? recipe;

  const CreateEditRecipeScreen({super.key, this.recipe});

  @override
  State<CreateEditRecipeScreen> createState() => _CreateEditRecipeScreenState();
}

class _CreateEditRecipeScreenState extends State<CreateEditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _timeController;
  late TextEditingController _caloriesController;
  late TextEditingController _servingsController;
  late TextEditingController _ingredientsController;
  late TextEditingController _stepsController;

  String _selectedCategory = 'Основні страви';
  String _selectedDifficulty = 'Середня';
  File? _selectedImage;
  String? _existingImageUrl;

  final List<String> _categories = [
    'Сніданки',
    'Перші страви',
    'Основні страви',
    'Салати',
    'Десерти',
  ];

  final List<String> _difficulties = ['Легка', 'Середня', 'Складна'];

  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController(text: widget.recipe?.name ?? '');
    _descriptionController = TextEditingController(text: widget.recipe?.description ?? '');
    _timeController = TextEditingController(text: widget.recipe?.time ?? '');
    _caloriesController = TextEditingController(
      text: widget.recipe != null ? widget.recipe!.calories.toString() : '',
    );
    _servingsController = TextEditingController(
      text: widget.recipe != null ? widget.recipe!.servings.toString() : '4',
    );
    _ingredientsController = TextEditingController(
      text: widget.recipe?.ingredients.join('\n') ?? '',
    );
    _stepsController = TextEditingController(
      text: widget.recipe?.steps.join('\n') ?? '',
    );

    if (widget.recipe != null) {
      _selectedCategory = widget.recipe!.category;
      _selectedDifficulty = widget.recipe!.difficulty;
      _existingImageUrl = widget.recipe!.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _timeController.dispose();
    _caloriesController.dispose();
    _servingsController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка вибору зображення: ${e.toString()}')),
      );
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final recipe = Recipe(
        id: widget.recipe?.id ?? '',
        name: _nameController.text.trim(),
        category: _selectedCategory,
        time: _timeController.text.trim(),
        calories: int.parse(_caloriesController.text.trim()),
        rating: widget.recipe?.rating ?? 0.0,
        emoji: widget.recipe?.emoji ?? '🍽️',
        description: _descriptionController.text.trim(),
        ingredients: _ingredientsController.text
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        steps: _stepsController.text
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        difficulty: _selectedDifficulty,
        servings: int.parse(_servingsController.text.trim()),
      );

      if (widget.recipe == null) {
        // Створення нового рецепту
        context.read<CreateRecipeBloc>().add(
              CreateRecipeSubmitEvent(
                recipe: recipe,
                imageFile: _selectedImage,
              ),
            );
      } else {
        // Оновлення існуючого рецепту
        context.read<UpdateRecipeBloc>().add(
              UpdateRecipeSubmitEvent(
                recipe: recipe,
                newImageFile: _selectedImage,
              ),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.recipe != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редагувати рецепт' : 'Новий рецепт'),
        backgroundColor: Colors.orange.shade500,
        foregroundColor: Colors.white,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<CreateRecipeBloc, CreateRecipeState>(
            listener: (context, state) {
              if (state is RecipeCreateSuccessState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Рецепт успішно створено!')),
                );
                Navigator.pop(context, true);
              } else if (state is RecipeCreateErrorState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.error)),
                );
              }
            },
          ),
          BlocListener<UpdateRecipeBloc, UpdateRecipeState>(
            listener: (context, state) {
              if (state is RecipeUpdateSuccessState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Рецепт успішно оновлено!')),
                );
                Navigator.pop(context, true);
              } else if (state is RecipeUpdateErrorState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.error)),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<CreateRecipeBloc, CreateRecipeState>(
          builder: (context, createState) {
            return BlocBuilder<UpdateRecipeBloc, UpdateRecipeState>(
              builder: (context, updateState) {
                final isLoading = createState is RecipeCreatingState ||
                    updateState is RecipeUpdatingState;

                return Stack(
                  children: [
                    Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildImageSection(),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _nameController,
                            label: 'Назва рецепту',
                            hint: 'Наприклад: Борщ український',
                            validator: (value) =>
                                value?.trim().isEmpty ?? true ? 'Введіть назву' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'Опис',
                            hint: 'Короткий опис рецепту',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            label: 'Категорія',
                            value: _selectedCategory,
                            items: _categories,
                            onChanged: (value) {
                              setState(() => _selectedCategory = value!);
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _timeController,
                                  label: 'Час приготування',
                                  hint: '60 хв',
                                  validator: (value) =>
                                      value?.trim().isEmpty ?? true ? 'Введіть час' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _caloriesController,
                                  label: 'Калорії',
                                  hint: '320',
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value?.trim().isEmpty ?? true) {
                                      return 'Введіть калорії';
                                    }
                                    if (int.tryParse(value!) == null) {
                                      return 'Тільки цифри';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdown(
                                  label: 'Складність',
                                  value: _selectedDifficulty,
                                  items: _difficulties,
                                  onChanged: (value) {
                                    setState(() => _selectedDifficulty = value!);
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _servingsController,
                                  label: 'Порцій',
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value?.trim().isEmpty ?? true) {
                                      return 'Введіть кількість';
                                    }
                                    if (int.tryParse(value!) == null) {
                                      return 'Тільки цифри';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _ingredientsController,
                            label: 'Інгредієнти (кожен з нового рядка)',
                            hint: 'Яловичина - 500 г\nБуряк - 2 шт',
                            maxLines: 10,
                            validator: (value) =>
                                value?.trim().isEmpty ?? true ? 'Додайте інгредієнти' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _stepsController,
                            label: 'Кроки приготування (кожен з нового рядка)',
                            hint: 'Відваріть м\'ясо до готовності\nНатріть буряк...',
                            maxLines: 10,
                            validator: (value) =>
                                value?.trim().isEmpty ?? true ? 'Додайте кроки' : null,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isEditing ? 'Зберегти зміни' : 'Створити рецепт',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                    if (isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.orange),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Зображення',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  )
                : _existingImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(_existingImageUrl!, fit: BoxFit.cover),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey.shade600),
                            const SizedBox(height: 8),
                            Text('Додати зображення', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }
}
