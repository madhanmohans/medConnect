import 'package:flutter/material.dart';

import '../../../../core/format.dart';
import '../../domain/models.dart';

/// Institution summary: name, university, location/type, beds and fees.
class InstitutionCard extends StatelessWidget {
  const InstitutionCard({
    super.key,
    required this.institution,
    required this.stateName,
    this.onTap,
  });

  final Institution institution;
  final String stateName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: const Icon(Icons.apartment_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(institution.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(institution.university, style: muted),
                    Text(
                      '${institution.city}, $stateName · ${institution.instituteType}',
                      style: muted,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 20,
                      runSpacing: 6,
                      children: [
                        _Stat(
                          icon: Icons.bed_outlined,
                          label: 'Beds',
                          value: formatCount(institution.beds),
                        ),
                        _Stat(
                          icon: Icons.payments_outlined,
                          label: 'Fee / year',
                          value: formatInrRange(
                            institution.feeMin,
                            institution.feeMax,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Column(
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
        ),
      ],
    );
  }
}
