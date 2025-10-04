import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:html' as html; // Web-specific imports

class AddBannersImages extends StatefulWidget {
  const AddBannersImages({super.key});

  @override
  State<AddBannersImages> createState() => _AddBannersImagesState();
}

class _AddBannersImagesState extends State<AddBannersImages> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  PlatformFile? _selectedFile;
  String? _errorMessage;
  String _selectedTab = 'diet';
  double _uploadProgress = 0;
  String? _previewUrl;

  Future<void> _pickImage() async {
    try {
      setState(() {
        _errorMessage = null;
        _previewUrl = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        withData: true,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.size > 5 * 1024 * 1024) {
          throw Exception('Image size too large (max 5MB)');
        }

        if (file.bytes != null) {
          final blob = html.Blob([file.bytes!]);
          _previewUrl = html.Url.createObjectUrlFromBlob(blob);
        }

        setState(() {
          _selectedFile = file;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Image selection failed: ${e.toString().replaceAll('Exception: ', '')}';
        _selectedFile = null;
        _previewUrl = null;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedFile == null || _selectedFile!.bytes == null) {
      setState(() => _errorMessage = 'No valid image selected');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _uploadProgress = 0;
      });

      final fileName =
          '${_selectedTab}_${DateTime.now().millisecondsSinceEpoch}.${_selectedFile!.extension ?? 'jpg'}';
      final storagePath = 'banners/$_selectedTab/$fileName';

      // Upload to Supabase Storage
      await _supabase.storage
          .from('banners')
          .uploadBinary(
            storagePath,
            _selectedFile!.bytes!,
            fileOptions: FileOptions(
              contentType: _getMimeType(_selectedFile!.extension),
              upsert: false,
            ),
          );

      // Get public URL
      final publicUrlResponse = _supabase.storage
          .from('banners')
          .getPublicUrl(storagePath);

      // Store metadata in Supabase table
      final response = await _supabase.from('banners').insert({
        'type': _selectedTab,
        'url': publicUrlResponse,
        'storage_path': storagePath,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (response.error != null) {
        throw Exception(response.error!.message);
      }

      setState(() {
        _selectedFile = null;
        _uploadProgress = 0;
        if (_previewUrl != null) {
          html.Url.revokeObjectUrl(_previewUrl!);
          _previewUrl = null;
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Upload successful!')));
    } catch (e) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getMimeType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  @override
  void dispose() {
    if (_previewUrl != null) {
      html.Url.revokeObjectUrl(_previewUrl!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Banner Image Manager'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 40 : 16,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Manage Banner Images',
                      style: theme.textTheme.headlineSmall,
                    ),
                    ToggleButtons(
                      isSelected: [
                        _selectedTab == 'diet',
                        _selectedTab == 'app',
                      ],
                      onPressed: (index) {
                        setState(
                          () => _selectedTab = index == 0 ? 'diet' : 'app',
                        );
                      },
                      children: const [Text('Diet'), Text('App')],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: theme.colorScheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage != null) const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Upload New Banner'),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _uploadImage,
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text('Upload'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _pickImage,
                          child: const Text('Select Image'),
                        ),
                        if (_selectedFile != null) ...[
                          const SizedBox(height: 16),
                          Text('Selected: ${_selectedFile!.name}'),
                          const SizedBox(height: 8),
                          if (_previewUrl != null)
                            Image.network(
                              _previewUrl!,
                              height: 150,
                              errorBuilder:
                                  (context, error, stackTrace) => Container(
                                    height: 150,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Text('Preview unavailable'),
                                    ),
                                  ),
                            ),
                        ],
                        if (_uploadProgress > 0) ...[
                          const SizedBox(height: 16),
                          LinearProgressIndicator(value: _uploadProgress),
                          Text(
                            '${(_uploadProgress * 100).toStringAsFixed(1)}%',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _supabase
                        .from('banners')
                        .stream(primaryKey: ['id'])
                        .eq('type', _selectedTab)
                        .order('created_at', ascending: false),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final banners = snapshot.data ?? [];

                      if (banners.isEmpty) {
                        return const Center(child: Text('No banners found'));
                      }

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 4 : 2,
                          childAspectRatio: 1.5,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        itemCount: banners.length,
                        itemBuilder: (context, index) {
                          final banner = banners[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CachedNetworkImage(
                                    imageUrl: banner['url'],
                                    fit: BoxFit.cover,
                                    errorWidget:
                                        (context, url, error) => Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: Icon(Icons.broken_image),
                                          ),
                                        ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                    onPressed:
                                        () => _showDeleteDialog(
                                          banner['id'],
                                          banner['storage_path'],
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(String docId, String storagePath) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Banner?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteImage(docId, storagePath);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteImage(String docId, String storagePath) async {
    try {
      setState(() => _isLoading = true);

      // Delete from database
      final dbResponse = await _supabase
          .from('banners')
          .delete()
          .eq('id', docId);
      if (dbResponse.error != null) {
        throw Exception(dbResponse.error!.message);
      }

      // Delete from storage
      await _supabase.storage.from('banners').remove([
        storagePath,
      ]);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Deleted successfully')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
