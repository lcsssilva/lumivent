import 'package:flutter/material.dart';

import '../i18n/app_strings_scope.dart';
import 'theme.dart';

class StatusDot extends StatelessWidget {
  const StatusDot(this.color, {super.key, this.size = 8});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Rounded badge with a colored dot and text.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.background,
  });
  final String label;
  final Color color;

  /// Backdrop for pills drawn over an image; defaults to a tint of [color].
  final Color? background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: background ?? color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusDot(color, size: 6),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

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

/// Settings row: label and description on the left, control on the right.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.control,
  });
  final String title;
  final Widget? subtitle;
  final Widget control;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: WeSizes.unit),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                DefaultTextStyle.merge(
                  style: const TextStyle(color: WeColors.muted, fontSize: 12.5),
                  child: subtitle!,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: WeSizes.unit * 2),
        control,
      ],
    ),
  );
}

/// Placeholder page for an area planned for a future phase.
class PhasePlaceholder extends StatelessWidget {
  const PhasePlaceholder({super.key, required this.phase, required this.items});
  final int phase;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final s = context.strings.shell;
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(WeSizes.unit * 3),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: WeCard(
            title: s.underConstruction,
            trailing: StatusPill(
              label: s.phase(phase),
              color: WeColors.accentHover,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: StatusDot(WeColors.border, size: 6),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(color: WeColors.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
