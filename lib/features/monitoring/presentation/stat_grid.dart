import 'package:flutter/material.dart';

import '../../../core/ui/theme.dart';

/// Grid of [StatTile]s with [columns] columns.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children, this.columns = 3});
  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      if (i > 0) rows.add(const SizedBox(height: WeSizes.unit * 2));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = i; j < i + columns; j++) ...[
              if (j > i) const SizedBox(width: WeSizes.unit * 2),
              Expanded(
                child: j < children.length ? children[j] : const SizedBox(),
              ),
            ],
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}
