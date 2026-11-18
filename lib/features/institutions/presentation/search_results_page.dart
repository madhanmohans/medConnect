import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/format.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/pager.dart';
import '../domain/models.dart';
import '../domain/search_query.dart';
import '../institution_providers.dart';
import 'widgets/filters_sheet.dart';
import 'widgets/search_form.dart';

class SearchResultsPage extends ConsumerWidget {
  const SearchResultsPage({super.key, required this.query});

  /// Null when the URL has no valid rank.
  final SearchQuery? query;

  static const wideBreakpoint = 900.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = query;
    if (q == null) {
      return AppScaffold(
        title: 'Search results',
        body: _Message(
          icon: Icons.search_off,
          text: 'Enter your rank to search.',
          action: FilledButton(
            onPressed: () => context.go(Routes.home),
            child: const Text('Go to search'),
          ),
        ),
      );
    }

    void show(SearchQuery next) => context.replace(
      Uri(
        path: Routes.search,
        queryParameters: next.toQueryParameters(),
      ).toString(),
    );

    final results = ref.watch(searchResultsProvider(q));

    return AppScaffold(
      title: 'Search results',
      body: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= wideBreakpoint;
          return CustomScrollView(
            // New scroll position for every page / query.
            key: ValueKey(q),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, wide ? 8 : 4),
                sliver: SliverToBoxAdapter(
                  child: _Header(
                    query: q,
                    result: results.value,
                    onChanged: show,
                  ),
                ),
              ),
              ...switch (results) {
                AsyncData(:final value) when value.items.isEmpty => [
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Message(
                      icon: Icons.inbox_outlined,
                      text: 'No seats match. Try removing some filters.',
                    ),
                  ),
                ],
                AsyncData(:final value) => [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: wide
                        ? SliverToBoxAdapter(
                            child: _ResultsTable(rows: value.items),
                          )
                        : SliverList.separated(
                            itemCount: value.items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) =>
                                _ResultCard(row: value.items[i]),
                          ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: Pager(
                        page: value.page,
                        totalPages: value.totalPages,
                        onPageChanged: (p) => show(q.withPage(p)),
                      ),
                    ),
                  ),
                ],
                AsyncError() => [
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Message(
                      icon: Icons.error_outline,
                      text: 'Could not load results.',
                    ),
                  ),
                ],
                _ => [
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              },
            ],
          );
        },
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.query,
    required this.result,
    required this.onChanged,
  });

  final SearchQuery query;
  final PagedResult<AllotmentRow>? result;
  final ValueChanged<SearchQuery> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stateNames = ref.watch(stateNamesProvider).value ?? const {};
    final courses = ref.watch(coursesProvider).value ?? const [];
    final institutions =
        ref.watch(institutionsProvider(null)).value ?? const [];
    String? courseName(String? id) =>
        courses.where((c) => c.id == id).firstOrNull?.name;
    String? instName(String? id) =>
        institutions.where((i) => i.id == id).firstOrNull?.name;

    final criteria = [
      'Rank ${formatCount(query.rank)}',
      ?stateNames[query.stateId],
      ?instName(query.institutionId),
      ?courseName(query.courseId),
    ];
    final r = result;
    final filterCount = query.extraFilterCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seats within your reach', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          r == null
              ? 'Searching…'
              : r.total == 0
              ? 'No records'
              : '${formatCount(r.firstIndex)}–${formatCount(r.lastIndex)} of ${formatCount(r.total)} records '
                    '(closing rank ≥ ${formatCount(query.rank)})',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final c in criteria)
              Chip(label: Text(c), visualDensity: VisualDensity.compact),
            ActionChip(
              avatar: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit search'),
              onPressed: () => _editSearch(context),
            ),
            ActionChip(
              avatar: const Icon(Icons.tune, size: 18),
              label: Text(
                filterCount == 0 ? 'Filters' : 'Filters ($filterCount)',
              ),
              onPressed: () async {
                final next = await showFiltersSheet(context, query);
                if (next != null) onChanged(next);
              },
            ),
            PopupMenuButton<SearchSort>(
              tooltip: 'Sort',
              initialValue: query.sort,
              onSelected: (s) => onChanged(query.withSort(s)),
              itemBuilder: (_) => [
                for (final s in SearchSort.values)
                  PopupMenuItem(value: s, child: Text(s.label)),
              ],
              child: Chip(
                avatar: const Icon(Icons.swap_vert, size: 18),
                label: Text('Sort: ${query.sort.label}'),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _editSearch(BuildContext context) async {
    final main = await showModalBottomSheet<SearchQuery>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(sheet).bottom,
        ),
        child: SingleChildScrollView(
          child: SearchForm(
            initial: query,
            submitLabel: 'Update results',
            onSubmit: (m) => Navigator.of(sheet).pop(m),
          ),
        ),
      ),
    );
    if (main != null) onChanged(query.withMain(main));
  }
}

/// Lookups for quota/category display names.
Map<String, String> _names(AsyncValue<List<Lookup>> v) => {
  for (final l in v.value ?? const <Lookup>[]) l.id: l.name,
};

class _ResultsTable extends ConsumerWidget {
  const _ResultsTable({required this.rows});

  final List<AllotmentRow> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotas = _names(ref.watch(quotasProvider));
    final categories = _names(ref.watch(categoriesProvider));
    final theme = Theme.of(context);
    const cols = [
      'Round',
      'AI Rank',
      'State',
      'Institute',
      'Course',
      'Quota',
      'Category',
      'Fee',
      'Stipend Yr 1',
      'Bond yrs',
      'Bond penalty',
      'Beds',
    ];
    const numeric = {
      'Round',
      'AI Rank',
      'Fee',
      'Stipend Yr 1',
      'Bond yrs',
      'Bond penalty',
      'Beds',
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          headingRowColor: WidgetStatePropertyAll(
            theme.colorScheme.surfaceContainerHigh,
          ),
          headingTextStyle: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          columnSpacing: 20,
          columns: [
            for (final c in cols)
              DataColumn(
                label: Text(c.toUpperCase()),
                numeric: numeric.contains(c),
              ),
          ],
          rows: [
            for (final r in rows)
              DataRow(
                onSelectChanged: (_) =>
                    context.push(Routes.institution(r.institution.id)),
                cells: [
                  DataCell(Text('${r.allotment.round}')),
                  DataCell(Text(formatCount(r.allotment.aiRank))),
                  DataCell(Text(r.stateName)),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: Text(
                        r.institution.name,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(r.course.name.toUpperCase())),
                  DataCell(
                    Text(quotas[r.allotment.quota] ?? r.allotment.quota),
                  ),
                  DataCell(
                    Text(
                      categories[r.allotment.category] ?? r.allotment.category,
                    ),
                  ),
                  DataCell(Text(formatInr(r.allotment.fee))),
                  DataCell(Text(formatInr(r.allotment.stipendYear1))),
                  DataCell(Text('${r.allotment.bondYears}')),
                  DataCell(Text(formatInr(r.allotment.bondPenalty))),
                  DataCell(Text(formatCount(r.allotment.beds))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends ConsumerWidget {
  const _ResultCard({required this.row});

  final AllotmentRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotas = _names(ref.watch(quotasProvider));
    final categories = _names(ref.watch(categoriesProvider));
    final theme = Theme.of(context);
    final a = row.allotment;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    Widget fact(String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: theme.textTheme.labelLarge),
      ],
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.institution(row.institution.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      row.institution.name,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'AIR ${formatCount(a.aiRank)}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text('${row.course.name} · ${row.stateName}', style: muted),
              const SizedBox(height: 10),
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  fact('Round', '${a.round}'),
                  fact('Quota', quotas[a.quota] ?? a.quota),
                  fact('Category', categories[a.category] ?? a.category),
                  fact('Fee', formatInr(a.fee)),
                  fact('Stipend Yr 1', formatInr(a.stipendYear1)),
                  fact(
                    'Bond',
                    '${a.bondYears} yr · ${formatInr(a.bondPenalty)}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}
