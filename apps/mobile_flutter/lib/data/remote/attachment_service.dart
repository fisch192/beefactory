import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'api_client.dart';

class AttachmentService {
  final ApiClient _client;
  final ImagePicker _picker = ImagePicker();

  AttachmentService(this._client);

  /// Pick a photo from camera or gallery.
  Future<XFile?> pickPhoto({bool fromCamera = false}) async {
    return _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
  }

  /// Upload a file to MinIO via presigned URL.
  /// Returns the object key (path) for storage in the event's attachments JSON.
  Future<String?> uploadFile(XFile file) async {
    try {
      final ext = p.extension(file.path).replaceFirst('.', '');
      final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';

      // Get presigned URL from backend
      final presignResponse = await _client.post('/attachments/presign', body: {
        'filename': p.basename(file.path),
        'content_type': contentType,
      });

      final uploadUrl = presignResponse['url'] as String?;
      final objectKey = presignResponse['key'] as String?;
      if (uploadUrl == null || objectKey == null) return null;

      // Upload directly to MinIO
      final bytes = await file.readAsBytes();
      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': contentType},
        body: bytes,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return objectKey;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
