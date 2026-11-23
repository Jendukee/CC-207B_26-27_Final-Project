// Thumbnails of the picked checklist photos plus "Camera" and "Gallery"
// buttons. Display only: the screen does the picking and keeps the list.
//
// OWNER: Member 3.

import 'package:flutter/material.dart';

import 'package:orange150_rental/core/theme/app_colors.dart';
import 'package:orange150_rental/features/checklist/models/checklist_photo.dart';

/// Photo thumbnails with add / remove buttons.
class PhotoPickerGrid extends StatelessWidget {
  /// Creates the grid.
  const PhotoPickerGrid({
    super.key,
    required this.photos,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
    this.enabled = true,
    this.maxPhotos = 10,
  });

  /// Picked photos.
  final List<ChecklistPhoto> photos;

  /// Take a photo with the camera.
  final VoidCallback onCamera;

  /// Choose photos from the gallery / files.
  final VoidCallback onGallery;

  /// Remove the photo at this index.
  final ValueChanged<int> onRemove;

  /// False while saving.
  final bool enabled;

  /// Most photos allowed.
  final int maxPhotos;

  @override
  Widget build(BuildContext context) {
    final canAdd = enabled && photos.length < maxPhotos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photos.isEmpty)
          const Text('No photos yet. Photos are optional but recommended.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (var i = 0; i < photos.length; i++) _thumbnail(i)],
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: canAdd ? onCamera : null,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Camera'),
            ),
            OutlinedButton.icon(
              onPressed: canAdd ? onGallery : null,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Gallery'),
            ),
          ],
        ),
        if (photos.length >= maxPhotos)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Maximum of $maxPhotos photos.'),
          ),
      ],
    );
  }

  /// One 88 x 88 thumbnail with a remove button and an "uploaded" tick.
  Widget _thumbnail(int index) {
    final photo = photos[index];
    return Semantics(
      label: 'Photo ${index + 1}${photo.isUploaded ? ', uploaded' : ''}',
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              photo.bytes,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
            ),
          ),
          if (photo.isUploaded)
            const Positioned(
              left: 4,
              bottom: 4,
              child: Icon(Icons.cloud_done, color: AppColors.success, size: 20),
            ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton.filledTonal(
              tooltip: 'Remove photo ${index + 1}',
              iconSize: 16,
              visualDensity: VisualDensity.compact,
              onPressed: enabled ? () => onRemove(index) : null,
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }
}
