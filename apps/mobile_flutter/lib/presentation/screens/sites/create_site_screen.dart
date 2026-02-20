import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../domain/models/site.dart';
import '../../providers/sites_provider.dart';
import '../../../services/ai_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class CreateSiteScreen extends StatefulWidget {
  const CreateSiteScreen({super.key});

  @override
  State<CreateSiteScreen> createState() => _CreateSiteScreenState();
}

class _CreateSiteScreenState extends State<CreateSiteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _elevationController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;
  bool _isLoadingGps = false;
  bool _isAnalyzingImg = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _elevationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchGps() async {
    setState(() => _isLoadingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      
      if (mounted) {
        setState(() {
          _latController.text = position.latitude.toStringAsFixed(6);
          _lngController.text = position.longitude.toStringAsFixed(6);
          if (position.altitude != 0) {
            _elevationController.text = position.altitude.toStringAsFixed(0);
          }
        });
      }
    } catch (_) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS Fehler: ${_}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  Future<void> _analyzeAreaWithAi() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (xFile == null) return;

    setState(() => _isAnalyzingImg = true);

    try {
      final bytes = await xFile.readAsBytes();
      final base64String = base64Encode(bytes);

      final response = await AiService.chat(
        history: [],
        userMessage: 'Bitte analysiere dieses Bild des geplanten Bienenstandorts. Nenne mir kurz die Vorteile und Nachteile der Umgebung für Bienen hinsichtlich Flora, Windschutz, Sonneneinstrahlung etc. als Aufzählungsliste.',
        imageBase64: base64String,
        imageMime: 'image/jpeg',
      );

      if (mounted) {
        final currentNotes = _notesController.text.trim();
        _notesController.text = currentNotes.isEmpty 
            ? response 
            : '$currentNotes\n\n--- KI Analyse ---\n$response';
      }
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('KI Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzingImg = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final site = SiteModel(
      name: _nameController.text.trim(),
      location: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      latitude: double.tryParse(_latController.text.trim()),
      longitude: double.tryParse(_lngController.text.trim()),
      elevation: double.tryParse(_elevationController.text.trim()),
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    final success =
        await context.read<SitesProvider>().createSite(site);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        context.pop();
      } else {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.tr('failed_to_save_site'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.tr('new_site')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: '${l.tr('site_name')} *',
                  hintText: l.tr('site_name_hint'),
                  prefixIcon: const Icon(Icons.edit),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l.tr('error_required_field');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l.tr('location'),
                  hintText: l.tr('location_hint'),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    'Koordinaten',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isLoadingGps ? null : _fetchGps,
                    icon: _isLoadingGps 
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location, size: 16),
                    label: Text(_isLoadingGps ? 'Ermittle...' : 'GPS abrufen'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFFA000),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l.tr('latitude'),
                        hintText: '48.137',
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final lat = double.tryParse(value);
                          if (lat == null || lat < -90 || lat > 90) {
                            return l.tr('error_valid_number');
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l.tr('longitude'),
                        hintText: '11.576',
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final lng = double.tryParse(value);
                          if (lng == null || lng < -180 || lng > 180) {
                            return l.tr('error_valid_number');
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _elevationController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l.tr('elevation_m'),
                  hintText: 'e.g. 520',
                  prefixIcon: const Icon(Icons.terrain),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  labelText: l.tr('notes'),
                  hintText: l.tr('notes_hint'),
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.notes),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              OutlinedButton.icon(
                onPressed: _isAnalyzingImg ? null : _analyzeAreaWithAi,
                icon: _isAnalyzingImg
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.smart_toy, size: 18),
                label: Text(
                  _isAnalyzingImg ? 'Analysiere Umgebung...' : 'Umgebung mit KI analysieren (Foto)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  side: const BorderSide(color: Colors.deepPurple),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l.tr('save_site')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
