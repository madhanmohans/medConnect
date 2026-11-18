import 'package:equatable/equatable.dart';

/// Search criteria. Serialised to/from URL query parameters so results pages
/// can be bookmarked and survive a browser refresh.
class SearchQuery extends Equatable {
  const SearchQuery({
    required this.rank,
    this.stateId,
    this.institutionId,
    this.courseId,
  });

  /// Returns null when the required rank is missing or invalid.
  static SearchQuery? fromQueryParameters(Map<String, String> p) {
    final rank = int.tryParse(p['rank'] ?? '');
    if (rank == null || rank < 1) return null;
    String? opt(String key) => (p[key]?.isEmpty ?? true) ? null : p[key];
    return SearchQuery(
      rank: rank,
      stateId: opt('state'),
      institutionId: opt('inst'),
      courseId: opt('course'),
    );
  }

  /// The student's All-India rank.
  final int rank;
  final String? stateId;
  final String? institutionId;
  final String? courseId;

  Map<String, String> toQueryParameters() => {
    'rank': '$rank',
    'state': ?stateId,
    'inst': ?institutionId,
    'course': ?courseId,
  };

  @override
  List<Object?> get props => [rank, stateId, institutionId, courseId];
}
