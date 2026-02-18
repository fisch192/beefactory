import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/remote/events_api.dart';
import '../../../l10n/app_localizations.dart';
import '../community/community_feed_screen.dart';
import 'treatment_screen.dart';

/// Varroa measurement methods.
enum VarroaMethod {
  stickyBoard('sticky_board', 'Varroawindel', Icons.grid_on),
  alcoholWash('alcohol_wash', 'Alkoholwaschung', Icons.local_bar),
  sugarRoll('sugar_roll', 'Puderzucker', Icons.cake),
  co2('co2', 'CO2', Icons.air);

  final String apiValue;
  final String label;
  final IconData icon;
  const VarroaMethod(this.apiValue, this.label, this.icon);
}

/// Threshold levels for varroa infestation.
enum VarroaThreshold { green, yellow, red }

/// Form screen for recording a varroa measurement. Computes normalized rate
/// in real-time, displays colour-coded threshold warnings, and can auto-suggest
/// creating a treatment task when the red threshold is exceeded.
class VarroaMeasurementScreen extends StatefulWidget {
  /// The hive this measurement is for.
  final String hiveId;
  final String? hiveName;

  const VarroaMeasurementScreen({
    super.key,
    required this.hiveId,
    this.hiveName,
  });

  @override
  State<VarroaMeasurementScreen> createState() =>
      _VarroaMeasurementScreenState();
}

class _VarroaMeasurementScreenState extends State<VarroaMeasurementScreen> {
  VarroaMethod _method = VarroaMethod.stickyBoard;
  final _mitesController = TextEditingController();
  final _durationController = TextEditingController(text: '48');
  bool _saving = false;

  @override
  void dispose() {
    _mitesController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Computed values
  // ---------------------------------------------------------------------------

  int? get _mitesCount => int.tryParse(_mitesController.text);

  int? get _durationHours {
    if (_method != VarroaMethod.stickyBoard) return null;
    return int.tryParse(_durationController.text);
  }

  /// Normalized rate: mites per day (sticky board) or mites per wash.
  double? get _normalizedRate {
    final mites = _mitesCount;
    if (mites == null) return null;

    if (_method == VarroaMethod.stickyBoard) {
      final hours = _durationHours;
      if (hours == null || hours <= 0) return null;
      return mites / (hours / 24.0);
    }
    // For wash / roll / co2: the raw count is the rate (mites per ~300 bees).
    return mites.toDouble();
  }

  VarroaThreshold get _threshold {
    final rate = _normalizedRate;
    if (rate == null) return VarroaThreshold.green;
    if (_method == VarroaMethod.stickyBoard) {
      if (rate < 1) return VarroaThreshold.green;
      if (rate <= 3) return VarroaThreshold.yellow;
      return VarroaThreshold.red;
    } else {
      if (rate < 1) return VarroaThreshold.green;
      if (rate <= 3) return VarroaThreshold.yellow;
      return VarroaThreshold.red;
    }
  }

  Color get _thresholdColor {
    switch (_threshold) {
      case VarroaThreshold.green:
        return Colors.green;
      case VarroaThreshold.yellow:
        return Colors.orange;
      case VarroaThreshold.red:
        return Colors.red;
    }
  }

  String _thresholdLabel(AppLocalizations l) {
    switch (_threshold) {
      case VarroaThreshold.green:
        return l.tr('varroa_low');
      case VarroaThreshold.yellow:
        return l.tr('varroa_medium');
      case VarroaThreshold.red:
        return l.tr('varroa_high');
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final mites = _mitesCount;
    if (mites == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.tr('enter_mite_count')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final eventsApi = context.read<EventsApi>();
      await eventsApi.createEvent({
        'type': 'VARROA_MEASUREMENT',
        'hive_id': widget.hiveId,
        'payload': {
          'method': _method.apiValue,
          'mites_count': mites,
          if (_durationHours != null) 'duration_hours': _durationHours,
          if (_normalizedRate != null) 'normalized_rate': _normalizedRate,
          'threshold': _threshold.name,
          'source': 'manual',
        },
      });

      if (!mounted) return;

      // If red threshold, suggest treatment.
      if (_threshold == VarroaThreshold.red) {
        final createTreatment = await _showTreatmentSuggestion();
        if (createTreatment == true && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => TreatmentScreen(
                hiveId: widget.hiveId,
                hiveName: widget.hiveName,
              ),
            ),
          );
          return;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.tr('varroa_saved')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool?> _showTreatmentSuggestion() {
    final l = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: Colors.red, size: 48),
        title: Text(l.tr('varroa_alert_title')),
        content: Text(l.tr('varroa_alert_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:
                Text(l.tr('later'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kHoneyAmber,
              foregroundColor: Colors.white,
            ),
            child: Text(l.tr('varroa_alert_action')),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    return Scaffold(
      backgroundColor: kHoneyAmberSurface,
      appBar: AppBar(
        title: Text(widget.hiveName != null
            ? '${l.tr('varroa_measurement')} - ${widget.hiveName}'
            : l.tr('varroa_measurement')),
        backgroundColor: kHoneyAmber,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Method selection
            Text(
              l.tr('measurement_method'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3E2723),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: VarroaMethod.values.map((method) {
                final selected = method == _method;
                return ChoiceChip(
                  avatar: Icon(
                    method.icon,
                    size: 18,
                    color: selected ? Colors.white : kHoneyAmberDark,
                  ),
                  label: Text(method.label),
                  selected: selected,
                  selectedColor: kHoneyAmber,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.grey[800],
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  onSelected: (_) => setState(() => _method = method),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Duration (sticky board only)
            if (_method == VarroaMethod.stickyBoard) ...[
              TextFormField(
                controller: _durationController,
                decoration: InputDecoration(
                  labelText: l.tr('duration_hours'),
                  hintText: 'z.B. 48',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon:
                      const Icon(Icons.timer_outlined, color: kHoneyAmber),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: kHoneyAmber, width: 2),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
            ],

            // Info text for wash methods
            if (_method != VarroaMethod.stickyBoard) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Zählen Sie die Milben pro ca. 300 Bienen '
                        '(ca. 1/2 Tasse Bienen).',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Mites count (large input)
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.bug_report,
                        size: 40, color: kHoneyAmberDark),
                    const SizedBox(height: 8),
                    Text(
                      l.tr('mite_count'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _mitesController,
                        decoration: const InputDecoration(
                          hintText: '0',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E2723),
                        ),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Normalized rate display
            if (_normalizedRate != null) ...[
              _RateIndicator(
                rate: _normalizedRate!,
                threshold: _threshold,
                thresholdColor: _thresholdColor,
                thresholdLabel: _thresholdLabel(l),
                isStickyBoard: _method == VarroaMethod.stickyBoard,
              ),
              const SizedBox(height: 16),
            ],

            // Threshold legend
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Schwellenwerte',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ThresholdLegendRow(
                      color: Colors.green,
                      label: _method == VarroaMethod.stickyBoard
                          ? '< 1 Milbe/Tag'
                          : '< 1 pro Waschung',
                      description: 'Gering',
                    ),
                    const SizedBox(height: 4),
                    _ThresholdLegendRow(
                      color: Colors.orange,
                      label: _method == VarroaMethod.stickyBoard
                          ? '1-3 Milben/Tag'
                          : '1-3 pro Waschung',
                      description: 'Erhöht',
                    ),
                    const SizedBox(height: 4),
                    _ThresholdLegendRow(
                      color: Colors.red,
                      label: _method == VarroaMethod.stickyBoard
                          ? '> 3 Milben/Tag'
                          : '> 3 pro Waschung',
                      description: 'Behandlung empfohlen',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? l.tr('syncing') : l.tr('save')),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget displaying the computed normalized rate with colour-coded indicator.
class _RateIndicator extends StatelessWidget {
  final double rate;
  final VarroaThreshold threshold;
  final Color thresholdColor;
  final String thresholdLabel;
  final bool isStickyBoard;

  const _RateIndicator({
    required this.rate,
    required this.threshold,
    required this.thresholdColor,
    required this.thresholdLabel,
    required this.isStickyBoard,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: thresholdColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: thresholdColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  threshold == VarroaThreshold.red
                      ? Icons.warning_amber_rounded
                      : threshold == VarroaThreshold.yellow
                          ? Icons.info_outline
                          : Icons.check_circle_outline,
                  color: thresholdColor,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  rate.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: thresholdColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isStickyBoard ? 'Milben/Tag' : 'pro Waschung',
                  style: TextStyle(
                    fontSize: 14,
                    color: thresholdColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              thresholdLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: thresholdColor,
              ),
            ),
            // Progress bar representing threshold
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (rate / 5).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.withValues(alpha: 0.15),
                color: thresholdColor,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row in the threshold legend.
class _ThresholdLegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String description;

  const _ThresholdLegendRow({
    required this.color,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        Text(
          description,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
