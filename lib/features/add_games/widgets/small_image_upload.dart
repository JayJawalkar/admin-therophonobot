import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class SmallImageUpload extends StatelessWidget {
  final PlatformFile? file;
  final VoidCallback onPressed;

  const SmallImageUpload({super.key, 
    required this.file,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  file!.bytes!,
                  fit: BoxFit.cover,
                ),
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 24,
                      color: colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add',
                      style: theme.textTheme.labelSmall?.copyWith(
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
