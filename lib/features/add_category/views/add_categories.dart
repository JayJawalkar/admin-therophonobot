import 'package:admin_therophonobot/features/add_games/widgets/game_item_card.dart';
import 'package:admin_therophonobot/features/add_games/widgets/small_image_upload.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admin_therophonobot/features/add_games/widgets/error_card.dart';
import 'package:admin_therophonobot/features/add_games/widgets/image_upload_card.dart';
import 'package:admin_therophonobot/features/add_games/widgets/section_card.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _categoryNameController;
  final List<GameFormData> _games = [];
  PlatformFile? _categoryImage;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _categoryNameController = TextEditingController();
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  Future<void> _pickCategoryImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _categoryImage = result.files.first;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Image selection failed: ${e.toString()}';
      });
    }
  }

  void _addGameForm() {
    setState(() {
      _games.add(GameFormData());
    });
  }

  void _removeGameForm(int index) {
    setState(() {
      _games.removeAt(index);
    });
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _errorMessage = 'Please provide a category name');
      return;
    }
    if (_categoryImage == null) {
      setState(() => _errorMessage = 'Please select a category image');
      return;
    }
    if (_games.isEmpty) {
      setState(() => _errorMessage = 'Please add at least one game');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Upload category image
      final categoryImageUrl = await _uploadFile(
        _categoryImage!,
        'category_images/${DateTime.now().millisecondsSinceEpoch}_${_categoryImage!.name}',
      );

      // 2. Create category document
      final categoryName = _categoryNameController.text.trim();
      final categoryRef = FirebaseFirestore.instance
          .collection('categories')
          .doc(categoryName); // Use category name as document ID

      await categoryRef.set({
        'name': categoryName,
        'imageUrl': categoryImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // 3. Process games
      for (final game in _games) {
        // Upload game banner
        final bannerUrl = await _uploadFile(
          game.banner!,
          'game_banners/${DateTime.now().millisecondsSinceEpoch}_${game.banner!.name}',
        );

        // Process game items
        final List<Map<String, dynamic>> items = [];
        for (final item in game.items) {
          final itemUrl = await _uploadFile(
            item['file'],
            'game_items/${DateTime.now().millisecondsSinceEpoch}_${item['file'].name}',
          );
          items.add({'name': item['name'], 'image': itemUrl});
        }

        // Add game to category's subcollection
        final gameName = game.nameController.text.trim();
        await categoryRef.collection('games').doc(gameName).set({
          'name': gameName,
          'bannerUrl': bannerUrl,
          'items': items,
        });
      }

      // 4. Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Category created successfully'),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
        _resetForm();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _uploadFile(PlatformFile file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    if (file.bytes == null) throw Exception('File bytes are null');
    await ref.putData(file.bytes!);
    return await ref.getDownloadURL();
  }

  void _resetForm() {
    _categoryNameController.clear();
    setState(() {
      _categoryImage = null;
      _games.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Category'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Reset Form'),
                      content: const Text('Clear all inputs?'),
                      actions: [
                        TextButton(
                          onPressed: Navigator.of(context).pop,
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            _resetForm();
                            Navigator.pop(context);
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 24,
          vertical: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category Details
              SectionCard(
                title: 'Category Details',
                icon: Icons.category,
                children: [
                  TextFormField(
                    controller: _categoryNameController,
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
                    ),
                    validator:
                        (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Category Image',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ImageUploadCard(
                    file: _categoryImage,
                    onPressed: _pickCategoryImage,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Games Section
              SectionCard(
                title: 'Games',
                icon: Icons.videogame_asset,
                children: [
                  ..._games.asMap().entries.map((entry) {
                    final index = entry.key;
                    final game = entry.value;
                    return GameForm(
                      gameData: game,
                      onRemove: () => _removeGameForm(index),
                    );
                  }).toList(),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _addGameForm,
                    icon: Icon(Icons.add, size: 20),
                    label: Text('Add Game'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                ErrorCard(
                  message: _errorMessage!,
                  onDismiss: () => setState(() => _errorMessage = null),
                ),
              ],

              const SizedBox(height: 24),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 0 : 80,
                ),
                child: FilledButton.tonal(
                  onPressed: _isLoading ? null : _saveCategory,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_outlined),
                              const SizedBox(width: 12),
                              Text(
                                'Save Category',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper class to manage each game's form data
class GameFormData {
  final TextEditingController nameController = TextEditingController();
  PlatformFile? banner;
  List<Map<String, dynamic>> items = [];
}

class GameForm extends StatefulWidget {
  final GameFormData gameData;
  final VoidCallback onRemove;

  const GameForm({super.key, required this.gameData, required this.onRemove});

  @override
  State<GameForm> createState() => _GameFormState();
}

class _GameFormState extends State<GameForm> {
  final TextEditingController _itemNameController = TextEditingController();
  PlatformFile? _currentItemImage;

  void _addGameItem() {
    if (_itemNameController.text.isEmpty || _currentItemImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide item name and image')),
      );
      return;
    }

    setState(() {
      widget.gameData.items.add({
        'name': _itemNameController.text.trim(),
        'file': _currentItemImage,
      });
      _itemNameController.clear();
      _currentItemImage = null;
    });
  }

  void _removeItem(int index) {
    setState(() {
      widget.gameData.items.removeAt(index);
    });
  }

  Future<void> _pickImage(bool isBanner) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          if (isBanner) {
            widget.gameData.banner = result.files.first;
          } else {
            _currentItemImage = result.files.first;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image selection failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: widget.gameData.nameController,
                    decoration: InputDecoration(
                      labelText: 'Game Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Game Banner',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ImageUploadCard(
              file: widget.gameData.banner,
              onPressed: () => _pickImage(true),
            ),
            const SizedBox(height: 12),
            // Items Form
            Material(
              color: colorScheme.surfaceVariant.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _itemNameController,
                        decoration: InputDecoration(
                          labelText: 'Item Name',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SmallImageUpload(
                      file: _currentItemImage,
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
                    ),
                  ],
                ),
              ),
            ),
            if (widget.gameData.items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isSmallScreen ? 2 : 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: widget.gameData.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.gameData.items[index];
                    return GameItemCard(
                      name: item['name'],
                      imageBytes: item['file']?.bytes,
                      onDelete: () => _removeItem(index),
                      onEdit: () {
                        _itemNameController.text = item['name'];
                        setState(() {
                          _currentItemImage = item['file'];
                          widget.gameData.items.removeAt(index);
                        });
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
