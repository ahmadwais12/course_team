import 'package:flutter/material.dart';

class FilterChipGroup extends StatelessWidget {
  final List<String> options;
  final String selected;
  final Function(String) onSelected;

  const FilterChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: options.map((option) {
        final isSelected = option == selected;
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onSelected(option),
          backgroundColor: Colors.grey[200],
          selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        );
      }).toList(),
    );
  }
}
