import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GameManagementScreen extends StatefulWidget {
  const GameManagementScreen({super.key});

  @override
  State<GameManagementScreen> createState() => _GameManagementScreenState();
}

class _GameManagementScreenState extends State<GameManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _gameNameController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();

  bool _isLoading = false;
  PlatformFile? _gameBanner;
  PlatformFile? _currentItemImage;

  List<Map<String, dynamic>> _gameItems = []; // Updated to store file too
  String? _errorMessage;

  Future<void> _pickImage(bool isBanner) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Required for bytes
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          if (isBanner) {
            _gameBanner = result.files.first;
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
    if (_itemNameController.text.isEmpty || _currentItemImage == null) {
      setState(() {
        _errorMessage = 'Please provide both item name and image';
      });
      return;
    }

    setState(() {
      _gameItems.add({
        'name': _itemNameController.text.trim(),
        'file': _currentItemImage, // Save file itself
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

    if (_gameBanner == null) {
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
      // Upload banner
      final bannerUrl = await _uploadFile(
        _gameBanner!,
        'game_banners/${DateTime.now().millisecondsSinceEpoch}_${_gameBanner!.name}',
      );

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

      // Save to Firestore
      await FirebaseFirestore.instance.collection('games').add({
        'name': _gameNameController.text.trim(),
        'bannerUrl': bannerUrl,
        'items': itemsWithUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _resetForm();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save game: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
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
      _gameBanner = null;
      _currentItemImage = null;
      _gameItems.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _gameItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Management'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Game Name
              TextFormField(
                controller: _gameNameController,
                decoration: InputDecoration(
                  labelText: 'Game Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // Game Banner
              _ImageUploadCard(
                title: 'Game Banner',
                file: _gameBanner,
                onPressed: () => _pickImage(true),
              ),
              const SizedBox(height: 20),

              // Add Items Section
              const Text(
                'Game Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _itemNameController,
                      decoration: InputDecoration(
                        labelText: 'Item Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _SmallImageUpload(
                    file: _currentItemImage,
                    onPressed: () => _pickImage(false),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, size: 40),
                    onPressed: _addGameItem,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Added Items List
              if (_gameItems.isNotEmpty) ...[
                const Text(
                  'Added Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_gameItems.length, (index) {
                    final item = _gameItems[index];
                    final PlatformFile file = item['file'];
                    return Chip(
                      label: Text(item['name']),
                      avatar: file.bytes != null
                          ? CircleAvatar(
                              backgroundImage: MemoryImage(file.bytes!),
                            )
                          : null,
                      onDeleted: () => _removeItem(index),
                    );
                  }),
                ),
                const SizedBox(height: 20),
              ],

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_errorMessage != null) const SizedBox(height: 16),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveGame,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Game',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Banner Upload Card Widget
class _ImageUploadCard extends StatelessWidget {
  final String title;
  final PlatformFile? file;
  final VoidCallback onPressed;

  const _ImageUploadCard({
    required this.title,
    required this.file,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: file != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            file!.bytes!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to select $title',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
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

// Item Image Upload Widget
class _SmallImageUpload extends StatelessWidget {
  final PlatformFile? file;
  final VoidCallback onPressed;

  const _SmallImageUpload({
    required this.file,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  file!.bytes!,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(
                Icons.image,
                color: Theme.of(context).colorScheme.outline,
              ),
      ),
    );
  }
}
