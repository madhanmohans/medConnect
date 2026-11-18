import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/auth_providers.dart';
import '../domain/search_query.dart';
import '../institution_providers.dart';
import 'widgets/institution_card.dart';
import 'widgets/search_form.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  static const wideBreakpoint = 900.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) return const SizedBox.shrink();

    void search(SearchQuery q) => context.push(
      Uri(
        path: Routes.search,
        queryParameters: q.toQueryParameters(),
      ).toString(),
    );

    final searchCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Find seats for your rank',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Only rank is required. Narrow down by state, institution or department.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SearchForm(initialRank: user.aiRank, onSubmit: search),
          ],
        ),
      ),
    );

    return AppScaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= wideBreakpoint;
          final greeting = Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Hi, ${user.name.split(' ').first}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          );
          if (wide) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 380,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [greeting, searchCard],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  const Expanded(child: _RecommendedList()),
                ],
              ),
            );
          }
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverList.list(
                  children: [greeting, searchCard, const SizedBox(height: 24)],
                ),
              ),
              const _RecommendedList(asSliver: true),
            ],
          );
        },
      ),
    );
  }
}

/// "Institutions for you": same state + preferred department.
class _RecommendedList extends ConsumerWidget {
  const _RecommendedList({this.asSliver = false});

  final bool asSliver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value!;
    final recommended = ref.watch(recommendedInstitutionsProvider);
    final stateNames = ref.watch(stateNamesProvider).value ?? const {};
    final courses = ref.watch(coursesProvider).value ?? const [];
    final courseName = courses
        .where((c) => c.id == user.courseId)
        .firstOrNull
        ?.name;
    final stateName = stateNames[user.stateId] ?? '';

    final header = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Institutions for you',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            [stateName, ?courseName].where((s) => s.isNotEmpty).join(' · '),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    final List<Widget> items = switch (recommended) {
      AsyncData(:final value) when value.isEmpty => [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text('No institutions found for your state yet.'),
        ),
      ],
      AsyncData(:final value) => [
        for (final inst in value)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InstitutionCard(
              institution: inst,
              stateName: stateNames[inst.stateId] ?? '',
              onTap: () => context.push(Routes.institution(inst.id)),
            ),
          ),
      ],
      AsyncError() => [const Text('Could not load institutions.')],
      _ => [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      ],
    };

    if (asSliver) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        sliver: SliverList.list(children: [header, ...items]),
      );
    }
    return ListView(children: [header, ...items]);
  }
}
