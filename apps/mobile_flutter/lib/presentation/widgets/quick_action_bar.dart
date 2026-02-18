import 'package:flutter/material.dart';

import '../screens/community/community_feed_screen.dart';

/// Definition of a single quick action button.
class QuickAction {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const QuickAction({
    required this.label,
    required this.icon,
    this.color,
    required this.onTap,
  });
}

/// Horizontal scrollable row of quick action buttons.
///
/// Pre-configured with the standard beekeeping actions: voice entry, quick
/// inspection, varroa check, add feeding, and add note. Each button navigates
/// to the appropriate screen via the [onVoiceEntry], [onInspection],
/// [onVarroaCheck], [onFeeding], and [onNote] callbacks.
class QuickActionBar extends StatelessWidget {
  /// Callback when the Voice Entry button is tapped.
  final VoidCallback? onVoiceEntry;

  /// Callback when the Quick Inspection button is tapped.
  final VoidCallback? onInspection;

  /// Callback when the Varroa Check button is tapped.
  final VoidCallback? onVarroaCheck;

  /// Callback when the Add Feeding button is tapped.
  final VoidCallback? onFeeding;

  /// Callback when the Add Note button is tapped.
  final VoidCallback? onNote;

  /// Optional additional custom actions appended after the defaults.
  final List<QuickAction> additionalActions;

  const QuickActionBar({
    super.key,
    this.onVoiceEntry,
    this.onInspection,
    this.onVarroaCheck,
    this.onFeeding,
    this.onNote,
    this.additionalActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final defaultActions = <QuickAction>[
      if (onVoiceEntry != null)
        QuickAction(
          label: 'Sprache',
          icon: Icons.mic,
          color: Colors.red,
          onTap: onVoiceEntry!,
        ),
      if (onInspection != null)
        QuickAction(
          label: 'Durchsicht',
          icon: Icons.assignment,
          color: Colors.indigo,
          onTap: onInspection!,
        ),
      if (onVarroaCheck != null)
        QuickAction(
          label: 'Varroa',
          icon: Icons.bug_report,
          color: Colors.deepOrange,
          onTap: onVarroaCheck!,
        ),
      if (onFeeding != null)
        QuickAction(
          label: 'Fütterung',
          icon: Icons.restaurant,
          color: Colors.green,
          onTap: onFeeding!,
        ),
      if (onNote != null)
        QuickAction(
          label: 'Notiz',
          icon: Icons.edit_note,
          color: Colors.blueGrey,
          onTap: onNote!,
        ),
    ];

    final allActions = [...defaultActions, ...additionalActions];

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allActions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final action = allActions[index];
          return _QuickActionButton(action: action);
        },
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final QuickAction action;

  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final color = action.color ?? kHoneyAmber;

    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(action.icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              action.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
