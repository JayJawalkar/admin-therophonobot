// add_game_screen.dart
import 'package:admin_therophonobot/features/add_games/service/game_controller.dart';
import 'package:admin_therophonobot/features/add_games/service/game_repository.dart';
import 'package:admin_therophonobot/features/add_games/widgets/error_card.dart';
import 'package:admin_therophonobot/features/add_games/widgets/game_item_card.dart';
import 'package:admin_therophonobot/features/add_games/widgets/image_upload_card.dart';
import 'package:admin_therophonobot/features/add_games/widgets/section_card.dart';
import 'package:admin_therophonobot/features/add_games/widgets/small_image_upload.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddGameScreen extends StatefulWidget {
  final String category;

  const AddGameScreen({super.key, required this.category});

  @override
  State<AddGameScreen> createState() => _AddGameScreenState();
}

class _AddGameScreenState extends State<AddGameScreen> {
  late GameController controller;
  final TextEditingController _gameNameController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _showEmojiPicker = false;
  String? _selectedCategory;
  String? _gameEmoji;

  final List<String> _difficultyCategories = ['Early', 'Moderate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    // Simple direct initialization
    controller = GameController(
      repository: GameRepository(supabaseClient: Supabase.instance.client),
    );
  }

  void _addGameItem() {
    controller.addGameItem(_itemNameController.text);

    if (controller.errorMessage == null) {
      _itemNameController.clear();
      setState(() {});
    }
  }

  Future<void> _saveGame() async {
    await controller.saveGame(
      gameName: _gameNameController.text,
      category: widget.category,
      emoji: _gameEmoji,
      description: _descriptionController.text,
      difficulty: _selectedCategory,
    );

    if (controller.errorMessage == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Game created successfully!'),
          backgroundColor: Theme.of(context).primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      _resetForm();
    } else {
      setState(() {}); // Refresh to show error
    }
  }

  void _resetForm() {
    _gameNameController.clear();
    _itemNameController.clear();
    _descriptionController.clear();
    setState(() {
      _gameEmoji = null;
      _selectedCategory = null;
      _showEmojiPicker = false;
    });

    controller.reset();
  }

  void _removeItem(int index) {
    controller.removeItem(index);
    setState(() {});
  }

  Future<void> _pickImage(bool isBanner) async {
    await controller.pickImage(isBanner);
    setState(() {});
  }

  Widget _buildCategorySpecificFields() {
    switch (widget.category) {
      case 'pathway':
        return _buildPathwayFields();
      case 'syllables':
        return _buildSyllablesFields();
      case 'home':
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPathwayFields() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        const SizedBox(height: 20),
        TextFormField(
          controller: _descriptionController,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Enter the pathway description',
            prefixIcon: const Icon(Icons.short_text),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Game Emoji',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              _showEmojiPicker = !_showEmojiPicker;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _gameEmoji ?? 'Select an emoji',
                  style: TextStyle(
                    fontSize: _gameEmoji != null ? 48 : 16,
                    color:
                        _gameEmoji != null
                            ? null
                            : colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showEmojiPicker) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                setState(() {
                  _gameEmoji = emoji.emoji;
                  _showEmojiPicker = false;
                });
              },
              config: const Config(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSyllablesFields() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            labelText: 'Difficulty Category',
            prefixIcon: const Icon(Icons.category_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
          ),
          items:
              _difficultyCategories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCategory = newValue;
            });
          },
        ),
      ],
    );
  }

  Widget _buildEmptyItemsState(ColorScheme colorScheme, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No items added yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items using the form above',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsGrid(
    bool isSmallScreen,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Added Items (${controller.gameItems.length})',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isSmallScreen ? 2 : 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: controller.gameItems.length,
          itemBuilder: (context, index) {
            final item = controller.gameItems[index];
            final PlatformFile? file = item['file'];
            return GameItemCard(
              name: item['name'],
              imageBytes: file?.bytes,
              onDelete: () => _removeItem(index),
              onEdit: () {
                _itemNameController.text = item['name'];
                controller.currentItemImage = item['file'];
                controller.removeItem(index);
                setState(() {});
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    final hasData =
        controller.gameItems.isNotEmpty ||
        controller.gameBanner != null ||
        _gameNameController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Game in ${widget.category}'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (hasData)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Reset Form'),
                        content: const Text(
                          'Are you sure you want to clear all inputs?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: Navigator.of(context).pop,
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _resetForm();
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                );
              },
              tooltip: 'Reset Form',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 24,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Game Details Section
            SectionCard(
              title: 'Game Details',
              icon: Icons.videogame_asset_outlined,
              children: [
                TextFormField(
                  controller: _gameNameController,
                  decoration: InputDecoration(
                    labelText: 'Game Name',
                    hintText: 'Enter the game title',
                    prefixIcon: const Icon(Icons.short_text),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
                  ),
                ),
                _buildCategorySpecificFields(),
                if (widget.category == 'home') ...[
                  const SizedBox(height: 20),
                  Text(
                    'Game Banner',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ImageUploadCard(
                    file: controller.gameBanner,
                    onPressed: () => _pickImage(true),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Game Items Section
            SectionCard(
              title: 'Game Items',
              icon: Icons.inventory_2_outlined,
              children: [
                // Add Item Row
                Material(
                  elevation: 0,
                  color: colorScheme.surfaceVariant.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _itemNameController,
                            decoration: const InputDecoration(
                              labelText: 'Item Name',
                              hintText: 'Enter item name',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SmallImageUpload(
                          file: controller.currentItemImage,
                          onPressed: () => _pickImage(false),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.add_circle,
                            size: 32,
                            color: colorScheme.primary,
                          ),
                          onPressed: _addGameItem,
                          tooltip: 'Add Item',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (controller.gameItems.isEmpty)
                  _buildEmptyItemsState(colorScheme, theme)
                else
                  _buildItemsGrid(isSmallScreen, theme, colorScheme),
              ],
            ),
            const SizedBox(height: 24),

            // Error Message
            if (controller.errorMessage != null)
              ErrorCard(
                message: controller.errorMessage!,
                onDismiss: () {
                  controller.errorMessage = null;
                  setState(() {});
                },
              ),
            if (controller.errorMessage != null) const SizedBox(height: 16),

            // Save Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 0 : 80),
              child: FilledButton.tonal(
                onPressed: controller.isLoading ? null : _saveGame,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                ),
                child:
                    controller.isLoading
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.save_outlined,
                              color: colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Save Game',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
