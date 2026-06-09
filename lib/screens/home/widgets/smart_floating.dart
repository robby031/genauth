import 'package:flutter/material.dart';
import 'package:genauth/utils/l10n_extensions.dart';

class SmartFloatingBubble extends StatelessWidget {
  const SmartFloatingBubble({
    super.key,
    required this.expanded,
    required this.onToggle,
    required this.onAdd,
    required this.onSearch,
    required this.onBackup,
    required this.addLabel,
    required this.searchLabel,
    required this.backupLabel,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onAdd;
  final VoidCallback onSearch;
  final VoidCallback onBackup;
  final String addLabel;
  final String searchLabel;
  final String backupLabel;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (expanded) ...[
            FloatingActionButton.small(
              heroTag: 'bubble-backup',
              onPressed: onBackup,
              tooltip: backupLabel,
              child: const Icon(Icons.backup_outlined),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: 'bubble-search',
              onPressed: onSearch,
              tooltip: searchLabel,
              child: const Icon(Icons.search),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: 'bubble-add',
              onPressed: onAdd,
              tooltip: addLabel,
              child: const Icon(Icons.add),
            ),
            const SizedBox(height: 10),
          ],
          FloatingActionButton(
            heroTag: 'bubble-main',
            onPressed: onToggle,
            tooltip: expanded ? context.l10n.close : context.l10n.quickActions,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                expanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.bolt_rounded,
                key: ValueKey(expanded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
