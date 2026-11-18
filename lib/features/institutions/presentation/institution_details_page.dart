import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/auth_providers.dart';
import '../domain/models.dart';
import '../institution_providers.dart';

class InstitutionDetailsPage extends ConsumerWidget {
  const InstitutionDetailsPage({super.key, required this.institutionId});

  final String institutionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final institution = ref.watch(institutionProvider(institutionId));
    return AppScaffold(
      title: 'Institution',
      maxWidth: 1000,
      body: switch (institution) {
        AsyncData(value: final inst?) => _Details(institution: inst),
        AsyncData() => const Center(child: Text('Institution not found.')),
        AsyncError() => const Center(
          child: Text('Could not load institution.'),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Details extends ConsumerWidget {
  const _Details({required this.institution});

  final Institution institution;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inst = institution;
    final stateName = ref.watch(stateNamesProvider).value?[inst.stateId] ?? '';
    final courses = {
      for (final c in ref.watch(coursesProvider).value ?? const <Course>[])
        c.id: c,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              child: const Icon(Icons.apartment_outlined, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inst.name, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(inst.university, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.place_outlined, size: 18),
                        label: Text('${inst.city}, $stateName'),
                        visualDensity: VisualDensity.compact,
                      ),
                      Chip(
                        avatar: const Icon(
                          Icons.account_balance_outlined,
                          size: 18,
                        ),
                        label: Text(inst.instituteType),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, c) {
            final perRow = c.maxWidth >= 720 ? 5 : (c.maxWidth >= 420 ? 3 : 2);
            final width = (c.maxWidth - 12 * (perRow - 1)) / perRow;
            final stats = [
              ('Beds', formatCount(inst.beds), Icons.bed_outlined),
              (
                'Fee / year',
                formatInrRange(inst.feeMin, inst.feeMax),
                Icons.payments_outlined,
              ),
              (
                'Stipend year 1',
                formatInr(inst.stipendYear1),
                Icons.savings_outlined,
              ),
              (
                'Bond',
                inst.bondYears == 0 ? 'None' : '${inst.bondYears} yr',
                Icons.gavel_outlined,
              ),
              (
                'Bond penalty',
                inst.bondPenalty == 0 ? '–' : formatInr(inst.bondPenalty),
                Icons.warning_amber_outlined,
              ),
            ];
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final (label, value, icon) in stats)
                  SizedBox(
                    width: width,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              icon,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(value, style: theme.textTheme.titleSmall),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Text('Courses offered', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final id in inst.courseIds)
              Chip(
                label: Text(
                  courses[id] == null
                      ? id
                      : '${courses[id]!.name} (${courses[id]!.degree})',
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _ClosingRanks(institutionId: inst.id),
      ],
    );
  }
}

/// Closing AI ranks per course and round, highlighting seats within the
/// signed-in student's rank.
class _ClosingRanks extends ConsumerWidget {
  const _ClosingRanks({required this.institutionId});

  final String institutionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rows = ref.watch(institutionAllotmentsProvider(institutionId));
    final userRank = ref.watch(authControllerProvider).value?.aiRank;
    final quotas = {
      for (final q in ref.watch(quotasProvider).value ?? const <Lookup>[])
        q.id: q.name,
    };
    final categories = {
      for (final c in ref.watch(categoriesProvider).value ?? const <Lookup>[])
        c.id: c.name,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Closing ranks', style: theme.textTheme.titleMedium),
        if (userRank != null)
          Text(
            'Ticked rows closed at or after your rank (${formatCount(userRank)}).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 8),
        switch (rows) {
          AsyncData(:final value) when value.isEmpty => const Text(
            'No allotment records.',
          ),
          AsyncData(:final value) => Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(
                  theme.colorScheme.surfaceContainerHigh,
                ),
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('COURSE')),
                  DataColumn(label: Text('ROUND'), numeric: true),
                  DataColumn(label: Text('QUOTA')),
                  DataColumn(label: Text('CATEGORY')),
                  DataColumn(label: Text('CLOSING RANK'), numeric: true),
                  DataColumn(label: Text('FEE'), numeric: true),
                ],
                rows: [
                  for (final r in value)
                    DataRow(
                      cells: [
                        DataCell(Text(r.course.name)),
                        DataCell(Text('${r.allotment.round}')),
                        DataCell(
                          Text(quotas[r.allotment.quota] ?? r.allotment.quota),
                        ),
                        DataCell(
                          Text(
                            categories[r.allotment.category] ??
                                r.allotment.category,
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (userRank != null &&
                                  r.allotment.aiRank >= userRank) ...[
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(formatCount(r.allotment.aiRank)),
                            ],
                          ),
                        ),
                        DataCell(Text(formatInr(r.allotment.fee))),
                      ],
                    ),
                ],
              ),
            ),
          ),
          AsyncError() => const Text('Could not load closing ranks.'),
          _ => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        },
      ],
    );
  }
}
