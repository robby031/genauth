import 'package:flutter/material.dart';

class TagFilterBar extends StatelessWidget {
  final Set<String> allTags;
  final Set<String> selectedTags;
  final ValueChanged<String> onToggle;

  const TagFilterBar({
    super.key,
    required this.allTags,
    required this.selectedTags,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (allTags.isEmpty) return const SizedBox.shrink();

    final sorted = allTags.toList()..sort();
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: sorted.length,
        separatorBuilder: (_, i) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final tag = sorted[i];
          final selected = selectedTags.contains(tag);
          return FilterChip(
            label: Text(tag),
            selected: selected,
            onSelected: (_) => onToggle(tag),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }
}
