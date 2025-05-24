import 'package:admin_therophonobot/features/add_games/widgets/error_card.dart';
import 'package:admin_therophonobot/features/add_games/widgets/game_item_card.dart';
import 'package:admin_therophonobot/features/add_games/widgets/section_card.dart';
import 'package:admin_therophonobot/features/add_games/widgets/small_image_upload.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddSyllablesGameScreen extends StatefulWidget {
  const AddSyllablesGameScreen({super.key});

  @override
  State<AddSyllablesGameScreen> createState() => _AddSyllablesGameScreenState();
}

class _AddSyllablesGameScreenState extends State<AddSyllablesGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _gameNameController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();

  bool _isLoading = false;
  PlatformFile? _currentItemImage;

  final List<Map<String, dynamic>> _gameItems = [];
  String? _errorMessage;

  final List<String> _categories = ['Early', 'Moderate', 'Advanced'];
  String? _selectedCategory;

  @override
  void dispose() {
    _gameNameController.dispose();
    _itemNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _currentItemImage = result.files.first;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Image selection failed: ${e.toString()}';
      });
    }
  }

  void _addGameItem() {
    if (_itemNameController.text.isEmpty || _currentItemImage == null) {
      setState(() {
        _errorMessage = 'Please provide both item name and image';
      });
      return;
    }

    setState(() {
      _gameItems.add({
        'name': _itemNameController.text.trim(),
        'file': _currentItemImage,
      });
      _itemNameController.clear();
      _currentItemImage = null;
      _errorMessage = null;
    });
  }

  Future<void> _saveGame() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = 'Please provide a game name';
      });
      return;
    }

    if (_gameItems.isEmpty) {
      setState(() {
        _errorMessage = 'Please add at least one game item';
      });
      return;
    }

    if (_selectedCategory == null) {
      setState(() {
        _errorMessage = 'Please select a category';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Upload all item images
      final List<Map<String, String>> itemsWithUrls = [];
      for (final item in _gameItems) {
        final PlatformFile file = item['file'];
        final imageRef = 'game_items/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final imageUrl = await _uploadFile(file, imageRef);

        itemsWithUrls.add({
          'name': item['name'],
          'image': imageUrl,
        });
      }

      // Get the game name and sanitize it for use as a document ID
      final gameName = _gameNameController.text.trim();
      final documentId = gameName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

      // Save to Firestore using game name as document ID
      await FirebaseFirestore.instance
          .collection('syllables')
          .doc(documentId)
          .set({
            'name': gameName,
            'items': itemsWithUrls,
            'category': _selectedCategory,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)); 

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Game saved successfully in $_selectedCategory!'),
          backgroundColor: Theme.of(context).primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      _resetForm();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save game: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<String> _uploadFile(PlatformFile file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      if (file.bytes == null) {
        throw Exception('File bytes are null');
      }
      await ref.putData(file.bytes!);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  void _resetForm() {
    _gameNameController.clear();
    _itemNameController.clear();
    setState(() {
      _currentItemImage = null;
      _gameItems.clear();
      _selectedCategory = null;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _gameItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Syllables Game'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_gameItems.isNotEmpty || _gameNameController.text.isNotEmpty || _selectedCategory != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset Form'),
                    content: const Text('Are you sure you want to clear all inputs?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
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
        child: Form(
          key: _formKey,
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
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Difficulty Category',
                      prefixIcon: const Icon(Icons.category_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
                    ),
                    items: _categories.map((String category) {
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
                    validator: (value) => value == null ? 'Please select a category' : null,
                  ),
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
                              decoration: InputDecoration(
                                labelText: 'Item Name',
                                hintText: 'Enter item name',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SmallImageUpload(
                            file: _currentItemImage,
                            onPressed: _pickImage,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.add_circle,
                                size: 32, color: colorScheme.primary),
                            onPressed: _addGameItem,
                            tooltip: 'Add Item',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_gameItems.isEmpty)
                    Padding(
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
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Added Items (${_gameItems.length})',
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
                          itemCount: _gameItems.length,
                          itemBuilder: (context, index) {
                            final item = _gameItems[index];
                            final PlatformFile file = item['file'];
                            return GameItemCard(
                              name: item['name'],
                              imageBytes: file.bytes,
                              onDelete: () => _removeItem(index),
                              onEdit: () {
                                _itemNameController.text = item['name'];
                                setState(() {
                                  _currentItemImage = item['file'];
                                  _gameItems.removeAt(index);
                                });
                              },
                            );
                          },
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null)
                ErrorCard(
                  message: _errorMessage!,
                  onDismiss: () => setState(() => _errorMessage = null),
                ),
              if (_errorMessage != null) const SizedBox(height: 16),

              // Save Button
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 0 : 80),
                child: FilledButton.tonal(
                  onPressed: _isLoading ? null : _saveGame,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_outlined,
                                color: colorScheme.onPrimaryContainer),
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
      ),
    );
  }
}