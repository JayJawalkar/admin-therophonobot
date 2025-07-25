import 'package:admin_therophonobot/features/add_games/widgets/error_card.dart';
import 'package:admin_therophonobot/features/add_games/widgets/game_item_card.dart';
import 'package:admin_therophonobot/features/add_games/widgets/image_upload_card.dart';
import 'package:admin_therophonobot/features/add_games/widgets/section_card.dart';
import 'package:admin_therophonobot/features/add_games/widgets/small_image_upload.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddHomeGameScreen extends StatefulWidget {
  final DocumentSnapshot? gameData; // Existing game data
  final String? documentId; // Document ID for editing

  const AddHomeGameScreen({super.key, this.gameData, this.documentId});

  @override
  State<AddHomeGameScreen> createState() => _AddHomeGameScreenState();
}

class _AddHomeGameScreenState extends State<AddHomeGameScreen> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _gameNameController;
  late final TextEditingController _itemNameController;
  bool _isLoading = false;
  PlatformFile? _gameBanner;
  PlatformFile? _currentItemImage;
  final List<Map<String, dynamic>> _gameItems = [];
  String? _errorMessage;
  String? _existingBannerUrl;
  // ignore: unused_field
  String? _generatedId;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _gameNameController = TextEditingController();
    _itemNameController = TextEditingController();

    if (widget.gameData != null) {
      final data = widget.gameData!.data() as Map<String, dynamic>;
      _gameNameController.text = data['name'];
      _existingBannerUrl = data['bannerUrl'];
      final List<dynamic> items = data['items'] ?? [];
      _gameItems.clear();
      for (var item in items) {
        _gameItems.add({
          'name': item['name'],
          'imageUrl': item['image'], // Store existing URLs
        });
      }
      _generatedId = widget.documentId;
    }
  }

  @override
  void dispose() {
    _gameNameController.dispose();
    _itemNameController.dispose();
    super.dispose();
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
            _gameBanner = result.files.first;
            _existingBannerUrl = null; // Clear existing URL if new image selected
          } else {
            _currentItemImage = result.files.first;
          }
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
    if (_itemNameController.text.isEmpty || (_currentItemImage == null && _currentItemImage == null)) {
      setState(() {
        _errorMessage = 'Please provide both item name and image';
      });
      return;
    }
    setState(() {
      _gameItems.add({
        'name': _itemNameController.text.trim(),
        'file': _currentItemImage,
        'imageUrl': _currentItemImage == null ? null : _existingBannerUrl, // Retain existing URL if no new file
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
    if (_gameBanner == null && _existingBannerUrl == null) {
      setState(() {
        _errorMessage = 'Please select a game banner';
      });
      return;
    }
    if (_gameItems.isEmpty) {
      setState(() {
        _errorMessage = 'Please add at least one game item';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String bannerUrl = _existingBannerUrl ?? await _uploadFile(
        _gameBanner!,
        'game_banners/${DateTime.now().millisecondsSinceEpoch}_${_gameBanner!.name}',
      );

      final List<Map<String, String>> itemsWithUrls = [];
      for (final item in _gameItems) {
        if (item['file'] != null) {
          final PlatformFile file = item['file'];
          final imageRef = 'game_items/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          final imageUrl = await _uploadFile(file, imageRef);
          itemsWithUrls.add({
            'name': item['name'],
            'image': imageUrl,
          });
        } else {
          itemsWithUrls.add({
            'name': item['name'],
            'image': item['imageUrl'], // Keep existing URL
          });
        }
      }

      final gameName = _gameNameController.text.trim();
      final documentIdToUse = widget.documentId ?? gameName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

      await FirebaseFirestore.instance
          .collection('home')
          .doc(documentIdToUse)
          .set({
            'name': gameName,
            'bannerUrl': bannerUrl,
            'items': itemsWithUrls,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.documentId != null ? 'Game updated' : 'Game created'),
          backgroundColor: Theme.of(context).primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      if (file.bytes == null) throw Exception('File bytes are null');
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
      _gameBanner = null;
      _currentItemImage = null;
      _gameItems.clear();
      _existingBannerUrl = null;
      _generatedId = null;
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
        title: Text(widget.documentId != null ? 'Edit Game' : 'Create New Game'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_gameItems.isNotEmpty || _gameBanner != null || _gameNameController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset Form'),
                    content: const Text('Are you sure you want to clear all inputs?'),
                    actions: [
                      TextButton(onPressed: Navigator.of(context).pop, child: const Text('Cancel')),
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
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24, vertical: 16),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Game Banner',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ImageUploadCard(
                    file: _gameBanner,
                    imageUrl: _existingBannerUrl,
                    onPressed: () => _pickImage(true),
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
                            onPressed: () => _pickImage(false),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.add_circle, size: 32, color: colorScheme.primary),
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
                            final PlatformFile? file = item['file'];
                            final String? imageUrl = item['imageUrl'];
                            return GameItemCard(
                              name: item['name'],
                              imageBytes: file?.bytes,
                              imageUrl: imageUrl,
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
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_outlined,
                                color: colorScheme.onPrimaryContainer),
                            const SizedBox(width: 12),
                            Text(
                              widget.documentId != null ? 'Update Game' : 'Save Game',
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