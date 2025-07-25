import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ImageUploadCard extends StatelessWidget {
  final PlatformFile? file;
  final String? imageUrl; // New parameter for existing URLs
  final VoidCallback onPressed;

  const ImageUploadCard({
    super.key,
    required this.onPressed,
    this.file,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AspectRatio(
      aspectRatio: 16 / 9, // Changed to recommended 16:9 ratio
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: (file != null || imageUrl != null)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Display either file or existing URL
                      if (file != null)
                        Image.memory(
                          file!.bytes!,
                          fit: BoxFit.cover,
                        )
                      else if (imageUrl != null)
                        CachedNetworkImage(
                          imageUrl:  imageUrl!,
                          fit: BoxFit.cover,
                          progressIndicatorBuilder: (context, child, loadingProgress) {
                            return Center(
                              child: CircularProgressIndicator(
                                
                              ),
                            );
                          },
                          errorWidget: (context, error, stackTrace) {
                            return Icon(Icons.error, color: colorScheme.error);
                          },
                        ),
                      // Edit button overlay
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: FloatingActionButton.small(
                          onPressed: onPressed,
                          heroTag: null,
                          backgroundColor: colorScheme.primaryContainer,
                          foregroundColor: colorScheme.onPrimaryContainer,
                          child: const Icon(Icons.edit),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 48,
                      color: colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to add banner image',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Recommended: 16:9 aspect ratio',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}