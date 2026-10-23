import 'package:flutter/material.dart';

import '../../../../core/ui/we_colors.dart';

/// Compact dropdown used by panels; a [value] not in [items] shows as empty.
class PanelDropdown<T> extends StatelessWidget {
  const PanelDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButton<T>(
    value: items.contains(value) ? value : null,
    isDense: true,
    underline: const SizedBox.shrink(),
    dropdownColor: WeColors.surface2,
    borderRadius: BorderRadius.circular(8),
    style: const TextStyle(fontSize: 13, color: WeColors.text),
    items: [
      for (final i in items)
        DropdownMenuItem<T>(value: i, child: Text(labelOf(i))),
    ],
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );
}
