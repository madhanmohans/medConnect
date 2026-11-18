import 'package:equatable/equatable.dart';

enum SearchSort {
  rank('Closing rank'),
  feeLow('Fee: low to high'),
  stipendHigh('Stipend: high to low');

  const SearchSort(this.label);
  final String label;

  static SearchSort fromName(String? name) =>
      values.firstWhere((s) => s.name == name, orElse: () => rank);
}

/// Search criteria. Serialised to/from URL query parameters so results pages
/// can be bookmarked and survive a browser refresh.
class SearchQuery extends Equatable {
  const SearchQuery({
    required this.rank,
    this.stateId,
    this.institutionId,
    this.courseId,
    this.quota,
    this.category,
    this.courseType,
    this.feeMax,
    this.bondYearsMax,
    this.sort = SearchSort.rank,
    this.page = 1,
  });

  /// Returns null when the required rank is missing or invalid.
  static SearchQuery? fromQueryParameters(Map<String, String> p) {
    final rank = int.tryParse(p['rank'] ?? '');
    if (rank == null || rank < 1) return null;
    String? opt(String key) => (p[key]?.isEmpty ?? true) ? null : p[key];
    int? optInt(String key) => int.tryParse(p[key] ?? '');
    return SearchQuery(
      rank: rank,
      stateId: opt('state'),
      institutionId: opt('inst'),
      courseId: opt('course'),
      quota: opt('quota'),
      category: opt('cat'),
      courseType: opt('type'),
      feeMax: optInt('feeMax'),
      bondYearsMax: optInt('bondMax'),
      sort: SearchSort.fromName(p['sort']),
      page: (optInt('page') ?? 1).clamp(1, 1 << 20),
    );
  }

  /// The student's All-India rank.
  final int rank;
  final String? stateId;
  final String? institutionId;
  final String? courseId;

  // Extra filters (from the filter sheet).
  final String? quota;
  final String? category;
  final String? courseType;
  final int? feeMax;
  final int? bondYearsMax;

  final SearchSort sort;

  /// 1-based page number.
  final int page;

  /// Number of optional filters in use (for the "Filters (n)" badge).
  int get extraFilterCount =>
      [quota, category, courseType, feeMax, bondYearsMax].nonNulls.length;

  Map<String, String> toQueryParameters() => {
    'rank': '$rank',
    'state': ?stateId,
    'inst': ?institutionId,
    'course': ?courseId,
    'quota': ?quota,
    'cat': ?category,
    'type': ?courseType,
    if (feeMax != null) 'feeMax': '$feeMax',
    if (bondYearsMax != null) 'bondMax': '$bondYearsMax',
    if (sort != SearchSort.rank) 'sort': sort.name,
    if (page != 1) 'page': '$page',
  };

  SearchQuery withPage(int page) => _copy(page: page);

  SearchQuery withSort(SearchSort sort) => _copy(sort: sort);

  /// Replaces the extra filters and goes back to page 1.
  SearchQuery withFilters({
    String? quota,
    String? category,
    String? courseType,
    int? feeMax,
    int? bondYearsMax,
  }) => SearchQuery(
    rank: rank,
    stateId: stateId,
    institutionId: institutionId,
    courseId: courseId,
    quota: quota,
    category: category,
    courseType: courseType,
    feeMax: feeMax,
    bondYearsMax: bondYearsMax,
    sort: sort,
  );

  /// Replaces the main criteria (keeps sort and extra filters), page 1.
  SearchQuery withMain(SearchQuery main) => SearchQuery(
    rank: main.rank,
    stateId: main.stateId,
    institutionId: main.institutionId,
    courseId: main.courseId,
    quota: quota,
    category: category,
    courseType: courseType,
    feeMax: feeMax,
    bondYearsMax: bondYearsMax,
    sort: sort,
  );

  SearchQuery _copy({SearchSort? sort, int? page}) => SearchQuery(
    rank: rank,
    stateId: stateId,
    institutionId: institutionId,
    courseId: courseId,
    quota: quota,
    category: category,
    courseType: courseType,
    feeMax: feeMax,
    bondYearsMax: bondYearsMax,
    sort: sort ?? this.sort,
    page: sort != null ? 1 : (page ?? this.page),
  );

  @override
  List<Object?> get props => [
    rank,
    stateId,
    institutionId,
    courseId,
    quota,
    category,
    courseType,
    feeMax,
    bondYearsMax,
    sort,
    page,
  ];
}
