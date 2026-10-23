import 'package:flutter/material.dart';

import 'we_sizes.dart';

/// Card with an optional title and content.
class WeCard extends StatelessWidget {
  const WeCard({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    this.padding,
    this.flat = false,
  });
  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// Draws only the title and content, without the card surface. Used for
  /// sections nested inside another card.
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  title!,
                  style: TextStyle(
                    fontSize: flat ? 13.5 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          SizedBox(height: flat ? WeSizes.unit : WeSizes.unit * 2),
        ],
        child,
      ],
    );
    if (flat) {
      return Padding(padding: padding ?? EdgeInsets.zero, child: content);
    }
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(WeSizes.unit * 2.5),
        child: content,
      ),
    );
  }
}
