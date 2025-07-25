import 'package:admin_therophonobot/features/add_games/widgets/game_item_card.dart';
import 'package:admin_therophonobot/features/add_games/widgets/small_image_upload.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admin_therophonobot/features/add_games/widgets/error_card.dart';
import 'package:admin_therophonobot/features/add_games/widgets/image_upload_card.dart';
import 'package:admin_therophonobot/features/add_games/widgets/section_card.dart';

class EditCategoryScreen extends StatefulWidget {
  final String categoryId;
  const EditCategoryScreen({super.key, required this.categoryId});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _categoryNameController;
  final List<GameFormData> _games = [];
  PlatformFile? _categoryImage;
  String? _categoryImageUrl;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _categoryNameController = TextEditingController();
    _loadCategoryData();
  }

  Future<void> _loadCategoryData() async {
    try {
      final categoryRef = FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.categoryId);
      final categoryDoc = await categoryRef.get();
      if (!categoryDoc.exists) {
        setState(() => _errorMessage = 'Category not found');
        return;
      }
      final data = categoryDoc.data()!;
      _categoryNameController.text = data['name'];
      _categoryImageUrl = data['imageUrl'];
      // Load games from subcollection
      final gamesSnapshot = await categoryRef.collection('games').get();
      for (var gameDoc in gamesSnapshot.docs) {
        final gameData = GameFormData();
        gameData.gameId = gameDoc.id;
        final game = gameDoc.data();
        gameData.nameController.text = game['name'];
        gameData.bannerUrl = game['bannerUrl'];
        // Load items
        final items = List<Map<String, dynamic>>.from(game['items'] ?? []);
        for (var item in items) {
          gameData.items.add({
            'name': item['name'],
            'imageUrl': item['image'],
          });
        }
        _games.add(gameData);
      }
      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load category: ${e.toString()}');
    }
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
      setState(() => _errorMessage = 'Image selection failed: ${e.toString()}');
    }
  }

  void _addGameForm() {
    setState(() => _games.add(GameFormData()));
  }

  void _removeGameForm(int index) {
    setState(() => _games.removeAt(index));
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _errorMessage = 'Please provide a category name');
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
      final categoryRef = FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.categoryId);
      String categoryImageUrl = _categoryImageUrl ?? '';
      if (_categoryImage != null) {
        categoryImageUrl = await _uploadFile(
          _categoryImage!,
          'category_images/${DateTime.now().millisecondsSinceEpoch}_${_categoryImage!.name}',
        );
      }
      // Update category document
      await categoryRef.update({
        'name': _categoryNameController.text.trim(),
        'imageUrl': categoryImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Process games
      for (final game in _games) {
        await _saveGame(game, categoryRef);
      }
      // Remove deleted games
      final currentGames = await categoryRef.collection('games').get();
      final currentGameIds = currentGames.docs.map((doc) => doc.id).toList();
      final gameIdsToKeep = _games
          .where((game) => game.gameId != null)
          .map((game) => game.gameId!)
          .toList();
      final gameIdsToDelete = currentGameIds
          .where((id) => !gameIdsToKeep.contains(id))
          .toList();
      for (final gameId in gameIdsToDelete) {
        await categoryRef.collection('games').doc(gameId).delete();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save category: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveGame(
      GameFormData game, DocumentReference categoryRef) async {
    final gamesCollection = categoryRef.collection('games');
    String bannerUrl = game.bannerUrl ?? '';
    // Upload new banner if selected
    if (game.bannerFile != null) {
      bannerUrl = await _uploadFile(
        game.bannerFile!,
        'game_banners/${DateTime.now().millisecondsSinceEpoch}_${game.bannerFile!.name}',
      );
    }
    // Process items
    final List<Map<String, dynamic>> items = [];
    for (final item in game.items) {
      if (item.containsKey('file')) {
        // New item - upload image
        final itemUrl = await _uploadFile(
          item['file'],
          'game_items/${DateTime.now().millisecondsSinceEpoch}_${item['file'].name}',
        );
        items.add({'name': item['name'], 'image': itemUrl});
      } else if (item.containsKey('imageUrl')) {
        // Existing item - keep URL
        items.add({'name': item['name'], 'image': item['imageUrl']});
      }
    }
    final gameData = {
      'name': game.nameController.text.trim(),
      'bannerUrl': bannerUrl,
      'items': items,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (game.gameId != null) {
      // Update existing game
      await gamesCollection.doc(game.gameId).update(gameData);
    } else {
      // Create new game
      await gamesCollection.add(gameData);
    }
  }

  Future<String> _uploadFile(PlatformFile file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    if (file.bytes == null) throw Exception('File bytes are null');
    await ref.putData(file.bytes!);
    return await ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Category')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Category'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Category'),
                  content: const Text('Are you sure you want to delete this category?'),
                  actions: [
                    TextButton(
                      onPressed: Navigator.of(context).pop,
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        try {
                          // Delete category and all associated games
                          final categoryRef = FirebaseFirestore.instance
                              .collection('categories')
                              .doc(widget.categoryId);
                          // Fetch all game IDs from the subcollection
                          final gamesSnapshot = await categoryRef.collection('games').get();
                          final gameIds = gamesSnapshot.docs.map((doc) => doc.id).toList();
                          // Delete games
                          for (var gameId in gameIds) {
                            await FirebaseFirestore.instance.collection('games').doc(gameId).delete();
                          }
                          // Delete category
                          await categoryRef.delete();
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Category deleted successfully')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error deleting category: $e')),
                          );
                        }
                      },
                      child: const Text('Delete'),
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
          horizontal: isSmallScreen ? 16 : isDesktop ? 80 : 40,
          vertical: 24,
        ),
        child: Center(
          child: SizedBox(
            width: isSmallScreen ? double.infinity : 800,
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
                            borderSide: BorderSide(color: colorScheme.outline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: theme.primaryColor, width: 2),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceVariant.withOpacity(0.1),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Category Image',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ImageUploadCard(
                        file: _categoryImage,
                        imageUrl: _categoryImageUrl,
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
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Add Game'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    ErrorCard(
                      message: _errorMessage!,
                      onDismiss: () =>
                          setState(() => _errorMessage = null),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 0 : isDesktop ? 80 : 40),
                    child: FilledButton.tonal(
                      onPressed: _isLoading ? null : _saveCategory,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_outlined),
                                const SizedBox(width: 12),
                                Text(
                                  'Save Changes',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper class to manage each game's form data
class GameFormData {
  final TextEditingController nameController = TextEditingController();
  PlatformFile? bannerFile;
  String? bannerUrl;
  String? gameId;
  List<Map<String, dynamic>> items = [];

  GameFormData({this.gameId});
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
  final _formKey = GlobalKey<FormState>();

  void _addGameItem() {
    if (_itemNameController.text.isEmpty || 
        (_currentItemImage == null && !widget.gameData.items.any((item) => item.containsKey('imageUrl')))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide item name and image')),
      );
      return;
    }
    setState(() {
      if (_currentItemImage != null) {
        widget.gameData.items.add({
          'name': _itemNameController.text.trim(),
          'file': _currentItemImage,
        });
      }
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
            widget.gameData.bannerFile = result.files.first;
          } else {
            _currentItemImage = result.files.first;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Image selection failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final crossAxisCount = isSmallScreen
        ? 2
        : MediaQuery.of(context).size.width >= 1200
            ? 4
            : 3;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
        color: colorScheme.surface.withOpacity(0.8),
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
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
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: theme.primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(Icons.delete, color: colorScheme.error),
                onPressed: widget.onRemove,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Game Banner',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ImageUploadCard(
            file: widget.gameData.bannerFile,
            imageUrl: widget.gameData.bannerUrl,
            onPressed: () => _pickImage(true),
          ),
          const SizedBox(height: 16),
          // Items Form
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surfaceVariant.withOpacity(0.2),
            ),
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _itemNameController,
                      decoration: InputDecoration(
                        labelText: 'Item Name',
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SmallImageUpload(
                    file: _currentItemImage,
                    onPressed: () => _pickImage(false),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(Icons.add_circle,
                        size: 32, color: colorScheme.primary),
                    onPressed: _addGameItem,
                  ),
                ],
              ),
            ),
          ),
          if (widget.gameData.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemCount: widget.gameData.items.length,
                itemBuilder: (context, index) {
                  final item = widget.gameData.items[index];
                  return GameItemCard(
                    name: item['name'],
                    imageBytes: item['file']?.bytes,
                    imageUrl: item['imageUrl'],
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
    );
  }
}