import 'package:flutter/material.dart';

import '../../../../core/i18n/app_strings_scope.dart';
import '../../../../core/ui/we_colors.dart';
import '../../../../core/ui/we_sizes.dart';
import '../../application/effect_filter.dart';

part 'explore_dropdown.dart';

/// Search, support filter and metadata filters of the Explore grid.
class ExploreFilters extends StatelessWidget {
  const ExploreFilters({
    super.key,
    required this.controller,
    required this.support,
    required this.tag,
    required this.publisher,
    required this.tags,
    required this.publishers,
    required this.onQuery,
    required this.onSupport,
    required this.onTag,
    required this.onPublisher,
  });

  final TextEditingController controller;
  final SupportFilter support;
  final String? tag, publisher;
  final List<String> tags, publishers;
  final VoidCallback onQuery;
  final ValueChanged<SupportFilter> onSupport;
  final ValueChanged<String?> onTag;
  final ValueChanged<String?> onPublisher;

  @override
  Widget build(BuildContext context) {
    final explore = context.strings.explore;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 250,
          child: TextField(
            key: const Key('explore-search'),
            controller: controller,
            onChanged: (_) => onQuery(),
            decoration: InputDecoration(
              isDense: true,
              hintText: explore.searchHint,
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        controller.clear();
                        onQuery();
                      },
                    ),
            ),
          ),
        ),
        for (final option in [
          (SupportFilter.all, explore.filterAll),
          (SupportFilter.compatible, explore.filterCompatible),
          (SupportFilter.partial, explore.filterPartial),
          (SupportFilter.unsupported, explore.filterUnsupported),
        ])
          ChoiceChip(
            key: ValueKey('filter-${option.$1.name}'),
            label: Text(option.$2),
            selected: support == option.$1,
            onSelected: (_) => onSupport(option.$1),
          ),
        if (tags.isNotEmpty)
          _ExploreDropdown(
            key: const Key('filter-tag'),
            value: tag,
            hint: explore.allCategories,
            values: tags,
            onChanged: onTag,
          ),
        if (publishers.isNotEmpty)
          _ExploreDropdown(
            key: const Key('filter-publisher'),
            value: publisher,
            hint: explore.allPublishers,
            values: publishers,
            onChanged: onPublisher,
          ),
      ],
    );
  }
}
