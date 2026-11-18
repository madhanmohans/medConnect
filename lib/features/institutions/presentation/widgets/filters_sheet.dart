import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/search_query.dart';
import '../../institution_providers.dart';

const courseTypes = [
  'Clinical',
  'Non-Clinical',
  'Para-Clinical',
  'Pre-Clinical',
];

/// Opens the extra-filters sheet; resolves to the updated query, or null if
/// dismissed.
Future<SearchQuery?> showFiltersSheet(
  BuildContext context,
  SearchQuery query,
) => showModalBottomSheet<SearchQuery>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => FiltersSheet(query: query),
);

class FiltersSheet extends ConsumerStatefulWidget {
  const FiltersSheet({super.key, required this.query});

  final SearchQuery query;

  @override
  ConsumerState<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<FiltersSheet> {
  late String? _quota = widget.query.quota;
  late String? _category = widget.query.category;
  late String? _courseType = widget.query.courseType;
  late int? _bondYearsMax = widget.query.bondYearsMax;

  /// Bumped on "Clear" so the form fields rebuild with empty values.
  int _generation = 0;
  late final _feeMax = TextEditingController(
    text: widget.query.feeMax?.toString() ?? '',
  );

  @override
  void dispose() {
    _feeMax.dispose();
    super.dispose();
  }

  void _clear() => setState(() {
    _generation++;
    _quota = _category = _courseType = null;
    _bondYearsMax = null;
    _feeMax.clear();
  });

  void _apply() => Navigator.of(context).pop(
    widget.query.withFilters(
      quota: _quota,
      category: _category,
      courseType: _courseType,
      feeMax: int.tryParse(_feeMax.text),
      bondYearsMax: _bondYearsMax,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final quotas = ref.watch(quotasProvider).value ?? const [];
    final categories = ref.watch(categoriesProvider).value ?? const [];

    Widget dropdown<T>({
      required String label,
      required T? value,
      required Map<T, String> options,
      required ValueChanged<T?> onChanged,
    }) => DropdownButtonFormField<T?>(
      key: ValueKey('$label-$_generation'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(value: null, child: Text('Any')),
        for (final e in options.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
      onChanged: onChanged,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filters', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            dropdown(
              label: 'Quota',
              value: _quota,
              options: {for (final q in quotas) q.id: q.name},
              onChanged: (v) => setState(() => _quota = v),
            ),
            const SizedBox(height: 12),
            dropdown(
              label: 'Category',
              value: _category,
              options: {for (final c in categories) c.id: c.name},
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),
            dropdown(
              label: 'Course type',
              value: _courseType,
              options: {for (final t in courseTypes) t: t},
              onChanged: (v) => setState(() => _courseType = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _feeMax,
              decoration: const InputDecoration(
                labelText: 'Maximum fee per year (₹)',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            dropdown(
              label: 'Maximum bond years',
              value: _bondYearsMax,
              options: {
                for (var y = 0; y <= 5; y++) y: y == 0 ? 'No bond' : '$y',
              },
              onChanged: (v) => setState(() => _bondYearsMax = v),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: _clear,
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _apply,
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
