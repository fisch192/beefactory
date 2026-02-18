import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../community/community_feed_screen.dart';

/// Available regions for zone selection.
const List<String> kRegions = ['suedtirol'];

/// Available elevation bands.
const List<String> kElevationBands = ['low', 'mid', 'high'];

/// Settings screen providing zone selection, language toggle, notification
/// settings, data export, account deletion, and app information.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _region = 'suedtirol';
  String _elevationBand = 'mid';
  bool _notificationsEnabled = true;
  String? _lastSyncTime;
  final String _appVersion = '1.0.0';

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _region = 'suedtirol';
      _elevationBand = 'mid';
      _notificationsEnabled = true;
      _lastSyncTime = null;
      _loading = false;
    });
  }

  void _showDeleteConfirmation() {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: Colors.red, size: 48),
        title: Text(l.tr('delete_confirm_title')),
        content: Text(l.tr('delete_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.tr('cancel'),
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l.tr('delete_not_implemented')),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l.tr('delete_final')),
          ),
        ],
      ),
    );
  }

  Future<void> _openStore() async {
    final uri = Uri.parse('https://www.imkereibedarf.it');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _exportData() {
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.tr('export_not_implemented')),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);

    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: kHoneyAmber),
        ),
      );
    }

    Map<String, String> elevationLabels = {
      'low': l.tr('low_elevation'),
      'mid': l.tr('mid_elevation'),
      'high': l.tr('high_elevation'),
    };

    return Scaffold(
      backgroundColor: kHoneyAmberSurface,
      appBar: AppBar(
        title: Text(l.tr('settings_title')),
        backgroundColor: kHoneyAmber,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --------------- Zone selection ---------------
          _SectionHeader(title: l.tr('zone')),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Region dropdown
                  _DropdownField<String>(
                    label: 'Region',
                    value: _region,
                    items: kRegions
                        .map((r) =>
                            DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _region = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Elevation band dropdown
                  _DropdownField<String>(
                    label: l.tr('elevation_level'),
                    value: _elevationBand,
                    items: kElevationBands.map((band) {
                      return DropdownMenuItem(
                        value: band,
                        child: Text(elevationLabels[band] ?? band),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _elevationBand = value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --------------- Language ---------------
          _SectionHeader(title: l.tr('language')),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.language, color: kHoneyAmber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.tr('language'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'de', label: Text('DE')),
                      ButtonSegment(value: 'it', label: Text('IT')),
                    ],
                    selected: {l.locale},
                    onSelectionChanged: (selection) {
                      l.setLocale(selection.first);
                    },
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return kHoneyAmber;
                        }
                        return Colors.grey[100];
                      }),
                      foregroundColor:
                          WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return Colors.grey[800];
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --------------- Notifications ---------------
          _SectionHeader(title: l.tr('notifications')),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              title: Text(l.tr('notifications')),
              subtitle: Text(
                _notificationsEnabled
                    ? l.tr('notifications_active')
                    : l.tr('notifications_off'),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              value: _notificationsEnabled,
              activeColor: kHoneyAmber,
              secondary: Icon(
                _notificationsEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: _notificationsEnabled ? kHoneyAmber : Colors.grey,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
              },
            ),
          ),
          const SizedBox(height: 16),

          // --------------- Store ---------------
          _SectionHeader(title: l.tr('shop')),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.storefront, color: kHoneyAmber),
              title: Text(l.tr('shop_title')),
              subtitle: Text(
                l.tr('shop_subtitle'),
                style: const TextStyle(fontSize: 13),
              ),
              trailing: const Icon(Icons.open_in_new),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onTap: () => _openStore(),
            ),
          ),
          const SizedBox(height: 16),

          // --------------- Data ---------------
          _SectionHeader(title: l.tr('data')),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download, color: kHoneyAmber),
                  title: Text(l.tr('export_data')),
                  subtitle: Text(
                    l.tr('export_subtitle'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onTap: _exportData,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading:
                      const Icon(Icons.delete_forever, color: Colors.red),
                  title: Text(
                    l.tr('delete_account'),
                    style: const TextStyle(color: Colors.red),
                  ),
                  subtitle: Text(
                    l.tr('delete_account_subtitle'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing:
                      const Icon(Icons.chevron_right, color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onTap: _showDeleteConfirmation,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --------------- App info ---------------
          _SectionHeader(title: l.tr('app_info')),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(label: l.tr('version'), value: _appVersion),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: l.tr('last_sync'),
                    value: _lastSyncTime != null
                        ? _formatSyncTime(_lastSyncTime!, l)
                        : l.tr('not_synced_yet'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatSyncTime(String iso, AppLocalizations l) {
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return l.tr('just_now');
      if (diff.inHours < 1) {
        return l.tr('minutes_ago').replaceAll('{n}', '${diff.inMinutes}');
      }
      if (diff.inHours < 24) {
        return l.tr('hours_ago').replaceAll('{n}', '${diff.inHours}');
      }
      return l.tr('days_ago').replaceAll('{n}', '${diff.inDays}');
    } catch (_) {
      return iso;
    }
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: kHoneyAmberDark,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kHoneyAmber, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF3E2723),
          ),
        ),
      ],
    );
  }
}
