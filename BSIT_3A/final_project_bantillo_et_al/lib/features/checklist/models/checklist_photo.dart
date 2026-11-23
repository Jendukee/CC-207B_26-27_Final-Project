// A photo picked for a checklist. It remembers its storage path after it
// is uploaded, so pressing Retry after a failed save does not upload the
// same photo twice.
//
// OWNER: Member 3.

import 'dart:typed_data';

/// One picked photo.
class ChecklistPhoto {
  /// Creates a photo from the picked [bytes].
  ChecklistPhoto({required this.bytes, this.mimeType});

  /// Image data (also used for the thumbnail).
  final Uint8List bytes;

  /// e.g. "image/jpeg"; null when the picker does not know.
  final String? mimeType;

  /// Path in the checklist-photos bucket once uploaded, else null.
  String? storagePath;

  /// True after a successful upload.
  bool get isUploaded => storagePath != null;
}
