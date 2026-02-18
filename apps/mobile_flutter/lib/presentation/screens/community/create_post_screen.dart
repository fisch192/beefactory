import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/community_provider.dart';
import 'community_feed_screen.dart';

/// Screen for creating a new community post.
///
/// Auto-fills region and elevation band from the user profile (passed in).
/// Validates title (required) and body (min 10 chars). Supports tag chip input
/// and optional photo attachment.
class CreatePostScreen extends StatefulWidget {
  final String? region;
  final String? elevationBand;

  const CreatePostScreen({
    super.key,
    this.region,
    this.elevationBand,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagController = TextEditingController();

  final List<String> _tags = [];
  final List<String> _photoUrls = [];
  final ImagePicker _imagePicker = ImagePicker();

  late String _region;
  late String _elevationBand;

  @override
  void initState() {
    super.initState();
    _region = _region ?? 'suedtirol';
    _elevationBand = _elevationBand ?? 'mid';
    if (_region == null || _elevationBand == null) {
      _loadPrefs();
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _region = _region ?? prefs.getString('user_region') ?? 'suedtirol';
        _elevationBand =
            _elevationBand ?? prefs.getString('user_elevation_band') ?? 'mid';
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmed = tag.trim().toLowerCase().replaceAll('#', '');
    if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
      setState(() {
        _tags.add(trimmed);
      });
    }
    _tagController.clear();
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _pickPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          // In a real app this would upload to storage and return a URL.
          // For now we store the local path as a placeholder.
          _photoUrls.add(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.tr('photo_error')}: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<CommunityProvider>();
    final success = await provider.createPost(
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      tags: _tags,
      photoUrls: _photoUrls,
      region: _region,
      elevationBand: _elevationBand,
    );

    if (!mounted) return;

    final l = AppLocalizations.of(context);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.tr('post_created')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              provider.createError ?? l.tr('post_create_error')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    return Scaffold(
      backgroundColor: kHoneyAmberSurface,
      appBar: AppBar(
        title: Text(l.tr('new_post')),
        backgroundColor: kHoneyAmber,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<CommunityProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Region info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kHoneyAmber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: kHoneyAmberLight.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: kHoneyAmberDark, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${_region} / ${_elevationBand}',
                          style: const TextStyle(
                            color: kHoneyAmberDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Automatisch',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title field
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: l.tr('title_required'),
                      hintText: l.tr('title_hint'),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: kHoneyAmber, width: 2),
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l.tr('title_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Body field
                  TextFormField(
                    controller: _bodyController,
                    decoration: InputDecoration(
                      labelText: l.tr('description_required'),
                      hintText: l.tr('description_hint'),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: kHoneyAmber, width: 2),
                      ),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 6,
                    minLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l.tr('description_required');
                      }
                      if (value.trim().length < 10) {
                        return l.tr('min_chars_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tags input
                  TextFormField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      labelText: l.tr('tags'),
                      hintText: l.tr('tags_hint'),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: kHoneyAmber, width: 2),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add, color: kHoneyAmber),
                        onPressed: () => _addTag(_tagController.text),
                      ),
                    ),
                    onFieldSubmitted: _addTag,
                  ),
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _tags.map((tag) {
                        return Chip(
                          label: Text(
                            '#$tag',
                            style: const TextStyle(
                              color: kHoneyAmberDark,
                              fontSize: 13,
                            ),
                          ),
                          backgroundColor:
                              kHoneyAmber.withValues(alpha: 0.15),
                          deleteIconColor: kHoneyAmberDark,
                          onDeleted: () => _removeTag(tag),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Photo attachment
                  OutlinedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.add_photo_alternate_outlined,
                        color: kHoneyAmber),
                    label: Text(
                      l.tr('add_photo_optional'),
                      style: const TextStyle(color: kHoneyAmberDark),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kHoneyAmberLight),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  if (_photoUrls.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _photoUrls.asMap().entries.map((entry) {
                        return Stack(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: kHoneyAmber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: kHoneyAmberLight
                                        .withValues(alpha: 0.5)),
                              ),
                              child: const Icon(Icons.image,
                                  color: kHoneyAmberDark),
                            ),
                            Positioned(
                              top: -4,
                              right: -4,
                              child: IconButton(
                                icon: const Icon(Icons.cancel,
                                    color: Colors.red, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    _photoUrls.removeAt(entry.key);
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: provider.creating ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kHoneyAmber,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            kHoneyAmber.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: provider.creating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(l.tr('publish_post')),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
