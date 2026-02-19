import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../screens/community/community_feed_screen.dart' show kHoneyAmber, kHoneyAmberDark;

/// A button that shows camera/gallery options for picking a photo.
class PhotoPickerButton extends StatelessWidget {
  final void Function(XFile file) onPicked;
  final int currentCount;
  final int maxPhotos;

  const PhotoPickerButton({
    super.key,
    required this.onPicked,
    this.currentCount = 0,
    this.maxPhotos = 3,
  });

  @override
  Widget build(BuildContext context) {
    final canAdd = currentCount < maxPhotos;
    return OutlinedButton.icon(
      onPressed: canAdd ? () => _showOptions(context) : null,
      icon: const Icon(Icons.add_a_photo, size: 18),
      label: Text(
        canAdd
            ? 'Add photo ($currentCount/$maxPhotos)'
            : 'Max photos reached',
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: kHoneyAmberDark,
        side: BorderSide(color: canAdd ? kHoneyAmber : Colors.grey),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final file = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 1920,
                  maxHeight: 1920,
                  imageQuality: 85,
                );
                if (file != null) onPicked(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final file = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1920,
                  maxHeight: 1920,
                  imageQuality: 85,
                );
                if (file != null) onPicked(file);
              },
            ),
          ],
        ),
      ),
    );
  }
}
