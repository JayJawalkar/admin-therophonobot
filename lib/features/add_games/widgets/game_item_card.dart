import 'dart:typed_data';

import 'package:flutter/material.dart';

class GameItemCard extends StatelessWidget {
  final String name;
  final Uint8List? imageBytes; // For new uploads
  final String? imageUrl; // For existing images from Firestore
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const GameItemCard({
    super.key,
    required this.name,
    this.imageBytes,
    this.imageUrl,
    required this.onDelete,
    required this.onEdit,
  }) : assert(imageBytes != null || imageUrl != null, 
      'Either imageBytes or imageUrl must be provided');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: _buildImageWidget(colorScheme),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onEdit,
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Icon(
                        Icons.edit,
                        size: 16,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Material(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onDelete,
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(ColorScheme colorScheme) {
    if (imageBytes != null) {
      // Display from local file (new upload)
      return Image.memory(
        imageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        
      );
    } else if (imageUrl != null) {
      // Display from network URL (existing image)
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              Icons.error_outline,
              color: colorScheme.error,
              size: 40,
            ),
          );
        },
      );
    }
    // Fallback placeholder (shouldn't happen due to assert)
    return Container(
      color: colorScheme.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 40,
          color: colorScheme.onSurface.withOpacity(0.3),
        ),
      ),
    );
  }
}