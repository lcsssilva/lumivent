part of 'explore_filters.dart';

class _ExploreDropdown extends StatelessWidget {
  const _ExploreDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.values,
    required this.onChanged,
  });

  final String? value;
  final String hint;
  final List<String> values;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: WeColors.surface2,
      borderRadius: BorderRadius.circular(WeSizes.radius),
      border: Border.all(color: WeColors.border),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value != null && values.contains(value) ? value! : '',
        isDense: true,
        dropdownColor: WeColors.surface2,
        style: const TextStyle(color: WeColors.text, fontSize: 13),
        items: [
          DropdownMenuItem(value: '', child: Text(hint)),
          for (final value in values)
            DropdownMenuItem(value: value, child: Text(value)),
        ],
        onChanged: (selected) =>
            onChanged(selected == null || selected.isEmpty ? null : selected),
      ),
    ),
  );
}
