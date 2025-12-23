class MindfulnessPractice {
  final String id;
  final String categoryId;
  final String difficultyLevel;
  final int durationSeconds;
  final String practiceType;
  final String? coverImagePath;
  final DateTime? createdAt;

  const MindfulnessPractice({
    required this.id,
    required this.categoryId,
    required this.difficultyLevel,
    required this.durationSeconds,
    required this.practiceType,
    this.coverImagePath,
    this.createdAt,
  });

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  factory MindfulnessPractice.fromMap(Map<String, dynamic> map) {
    final dynamic cat = map['mindfulnessCategory'];
    final String? iconPath =
    (cat is Map<String, dynamic>) ? cat['icon_path']?.toString() : null;
    return MindfulnessPractice(
      id: map['mind_practice_id'].toString(),
      categoryId: map['mind_category_id'].toString(),
      difficultyLevel: (map['difficulty_level'] ?? '').toString(),
      durationSeconds: _toInt(map['duration_seconds']),
      practiceType: (map['practice_type'] ?? '').toString(),
      coverImagePath: map['cover_image_path']?.toString(),
      createdAt: _toDateTime(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mind_practice_id': id,
      'mind_category_id': categoryId,
      'difficulty_level': difficultyLevel,
      'duration_seconds': durationSeconds,
      'practice_type': practiceType,
      'cover_image_path': coverImagePath,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
