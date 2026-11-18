import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/validators.dart';
import '../../domain/search_query.dart';
import '../../institution_providers.dart';

/// Rank (required) + optional state, institution and department.
/// The institution list is narrowed to the selected state.
class SearchForm extends ConsumerStatefulWidget {
  const SearchForm({
    super.key,
    required this.onSubmit,
    this.initialRank,
    this.initial,
    this.submitLabel = 'Search',
  });

  final ValueChanged<SearchQuery> onSubmit;
  final int? initialRank;
  final SearchQuery? initial;
  final String submitLabel;

  @override
  ConsumerState<SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends ConsumerState<SearchForm> {
  final _formKey = GlobalKey<FormState>();
  late final _rank = TextEditingController(
    text: '${widget.initial?.rank ?? widget.initialRank ?? ''}',
  );
  late String? _stateId = widget.initial?.stateId;
  late String? _institutionId = widget.initial?.institutionId;
  late String? _courseId = widget.initial?.courseId;

  @override
  void dispose() {
    _rank.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      SearchQuery(
        rank: int.parse(_rank.text.trim()),
        stateId: _stateId,
        institutionId: _institutionId,
        courseId: _courseId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final states = ref.watch(statesProvider).value ?? const [];
    final courses = ref.watch(coursesProvider).value ?? const [];
    final institutions =
        ref.watch(institutionsProvider(_stateId)).value ?? const [];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _rank,
            decoration: const InputDecoration(
              labelText: 'Your All-India rank',
              prefixIcon: Icon(Icons.emoji_events_outlined),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: Validators.rank,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          _OptionalDropdown(
            label: 'State',
            anyLabel: 'Any state',
            icon: Icons.place_outlined,
            value: _stateId,
            options: {for (final s in states) s.id: s.name},
            onChanged: (v) => setState(() {
              _stateId = v;
              _institutionId = null;
            }),
          ),
          const SizedBox(height: 12),
          _OptionalDropdown(
            // Rebuild when the state changes so the selection resets.
            key: ValueKey('inst-$_stateId'),
            label: 'Institution',
            anyLabel: 'Any institution',
            icon: Icons.apartment_outlined,
            value: _institutionId,
            options: {for (final i in institutions) i.id: i.name},
            onChanged: (v) => setState(() => _institutionId = v),
          ),
          const SizedBox(height: 12),
          _OptionalDropdown(
            label: 'Department',
            anyLabel: 'Any department',
            icon: Icons.medical_services_outlined,
            value: _courseId,
            options: {for (final c in courses) c.id: '${c.name} (${c.degree})'},
            onChanged: (v) => setState(() => _courseId = v),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.search),
            label: Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}

/// Searchable dropdown with an "Any" (null) option.
class _OptionalDropdown extends StatelessWidget {
  const _OptionalDropdown({
    super.key,
    required this.label,
    required this.anyLabel,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String anyLabel;
  final IconData icon;
  final String? value;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String?>(
      // Recreate when options load so the initial label is shown.
      key: ValueKey('$label-${options.length}'),
      label: Text(label),
      leadingIcon: Icon(icon),
      initialSelection: value,
      expandedInsets: EdgeInsets.zero,
      enableFilter: true,
      requestFocusOnTap: true,
      menuHeight: 320,
      dropdownMenuEntries: [
        DropdownMenuEntry(value: null, label: anyLabel),
        for (final e in options.entries)
          DropdownMenuEntry(value: e.key, label: e.value),
      ],
      onSelected: onChanged,
    );
  }
}
