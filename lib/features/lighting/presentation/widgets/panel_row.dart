import 'package:flutter/material.dart';

/// Row with a label on the left and a control on the right.
class PanelRow extends StatelessWidget {
  const PanelRow({super.key, required this.label, required this.control});
  final String label;
  final Widget control;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        control,
      ],
    ),
  );
}
