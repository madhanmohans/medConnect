import 'package:equatable/equatable.dart';

/// Simple id/name pair used for states, quotas and categories.
class Lookup extends Equatable {
  const Lookup({required this.id, required this.name});

  factory Lookup.fromJson(Map<String, dynamic> json) =>
      Lookup(id: json['id'] as String, name: json['name'] as String);

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

class Course extends Equatable {
  const Course({
    required this.id,
    required this.name,
    required this.courseType,
    required this.degree,
  });

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    id: json['id'] as String,
    name: json['name'] as String,
    courseType: json['courseType'] as String,
    degree: json['degree'] as String,
  );

  final String id;
  final String name;

  /// Clinical, Non-Clinical, Para-Clinical or Pre-Clinical.
  final String courseType;

  /// MD, MS, DNB, Diploma, MPH...
  final String degree;

  @override
  List<Object?> get props => [id];
}

class Institution extends Equatable {
  const Institution({
    required this.id,
    required this.name,
    required this.university,
    required this.stateId,
    required this.city,
    required this.instituteType,
    required this.beds,
    required this.feeMin,
    required this.feeMax,
    required this.stipendYear1,
    required this.bondYears,
    required this.bondPenalty,
    required this.courseIds,
  });

  factory Institution.fromJson(Map<String, dynamic> json) => Institution(
    id: json['id'] as String,
    name: json['name'] as String,
    university: json['university'] as String,
    stateId: json['stateId'] as String,
    city: json['city'] as String,
    instituteType: json['instituteType'] as String,
    beds: json['beds'] as int,
    feeMin: json['feeMin'] as int,
    feeMax: json['feeMax'] as int,
    stipendYear1: json['stipendYear1'] as int,
    bondYears: json['bondYears'] as int,
    bondPenalty: json['bondPenalty'] as int,
    courseIds: (json['courseIds'] as List).cast<String>(),
  );

  final String id;
  final String name;
  final String university;
  final String stateId;
  final String city;
  final String instituteType;
  final int beds;
  final int feeMin;
  final int feeMax;
  final int stipendYear1;
  final int bondYears;
  final int bondPenalty;
  final List<String> courseIds;

  @override
  List<Object?> get props => [id];
}

/// One allotment record: a seat in [courseId] at [institutionId] that closed
/// at All-India rank [aiRank] in a given counselling round.
class Allotment extends Equatable {
  const Allotment({
    required this.id,
    required this.session,
    required this.round,
    required this.aiRank,
    required this.institutionId,
    required this.courseId,
    required this.quota,
    required this.category,
    required this.fee,
    required this.stipendYear1,
    required this.bondYears,
    required this.bondPenalty,
    required this.beds,
  });

  factory Allotment.fromJson(Map<String, dynamic> json) => Allotment(
    id: json['id'] as String,
    session: json['session'] as int,
    round: json['round'] as int,
    aiRank: json['aiRank'] as int,
    institutionId: json['institutionId'] as String,
    courseId: json['courseId'] as String,
    quota: json['quota'] as String,
    category: json['category'] as String,
    fee: json['fee'] as int,
    stipendYear1: json['stipendYear1'] as int,
    bondYears: json['bondYears'] as int,
    bondPenalty: json['bondPenalty'] as int,
    beds: json['beds'] as int,
  );

  final String id;
  final int session;
  final int round;
  final int aiRank;
  final String institutionId;
  final String courseId;
  final String quota;
  final String category;
  final int fee;
  final int stipendYear1;
  final int bondYears;
  final int bondPenalty;
  final int beds;

  @override
  List<Object?> get props => [id];
}

/// An [Allotment] joined with its institution, course and state for display.
class AllotmentRow {
  const AllotmentRow({
    required this.allotment,
    required this.institution,
    required this.course,
    required this.stateName,
  });

  final Allotment allotment;
  final Institution institution;
  final Course course;
  final String stateName;
}

class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<T> items;
  final int total;

  /// 1-based page number.
  final int page;
  final int pageSize;

  int get totalPages => total == 0 ? 1 : (total + pageSize - 1) ~/ pageSize;
  int get firstIndex => total == 0 ? 0 : (page - 1) * pageSize + 1;
  int get lastIndex => (firstIndex + items.length - 1).clamp(0, total);
}
