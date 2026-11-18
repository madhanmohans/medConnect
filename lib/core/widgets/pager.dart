import 'package:flutter/material.dart';

/// Numbered pagination: ‹ 1 … 4 5 6 … 20 ›
class Pager extends StatelessWidget {
  const Pager({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  /// Page numbers to show; null marks a gap ("…").
  static List<int?> window(int page, int totalPages, {int radius = 1}) {
    final pages = <int>{
      1,
      totalPages,
      for (var p = page - radius; p <= page + radius; p++)
        if (p >= 1 && p <= totalPages) p,
    }.toList()..sort();
    final out = <int?>[];
    for (final p in pages) {
      if (out.isNotEmpty && p - out.last! > 1) {
        // A gap of exactly one page is shown as the page itself.
        if (p - out.last! == 2) {
          out.add(p - 1);
        } else {
          out.add(null);
        }
      }
      out.add(p);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        IconButton(
          tooltip: 'Previous page',
          onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        for (final p in window(page, totalPages))
          if (p == null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('…'),
            )
          else
            SizedBox(
              height: 36,
              child: p == page
                  ? Semantics(
                      label: 'Page $p, current page',
                      excludeSemantics: true,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 36),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            '$p',
                            style: TextStyle(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    )
                  : OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(36, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: () => onPageChanged(p),
                      child: Text('$p'),
                    ),
            ),
        IconButton(
          tooltip: 'Next page',
          onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
