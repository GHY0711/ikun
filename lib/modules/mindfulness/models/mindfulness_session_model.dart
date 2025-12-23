class MindfulnessSession {
  final String sessionId; // session_id (int8) -> String
  final String userId; // user_id (int8) -> String
  final String practiceId; // mind_practice_id (int8) -> String
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSeconds;
  final String completionStatus;
  final double completionRate;
  final int? preMood;
  final int? postMood;
  final DateTime? createdAt;

  const MindfulnessSession({
    required this.sessionId,
    required this.userId,
    required this.practiceId,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.completionStatus,
    required this.completionRate,
    this.preMood,
    this.postMood,
    this.createdAt,
  });

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static double _toDouble(dynamic v, {double fallback = 0}) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static DateTime _toDateTimeRequired(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) {
      final parsed = DateTime.tryParse(v);
      if (parsed != null) return parsed;
    }
    // 最后兜底
    return DateTime.now();
  }

  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  factory MindfulnessSession.fromMap(Map<String, dynamic> map) {
    return MindfulnessSession(
      sessionId: map['session_id'].toString(),
      userId: map['user_id'].toString(),
      practiceId: map['mind_practice_id'].toString(),
      startedAt: _toDateTimeRequired(map['started_at']),
      endedAt: _toDateTimeRequired(map['ended_at']),
      durationSeconds: _toInt(map['duration_seconds']),
      completionStatus: (map['completion_status'] ?? '').toString(),
      completionRate: _toDouble(map['completion_rate'], fallback: 0),
      preMood: map['pre_mood'] == null ? null : _toInt(map['pre_mood']),
      postMood: map['post_mood'] == null ? null : _toInt(map['post_mood']),
      createdAt: _toDateTime(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'user_id': userId,
      'mind_practice_id': practiceId,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt.toIso8601String(),
      'duration_seconds': durationSeconds,
      'completion_status': completionStatus,
      'completion_rate': completionRate,
      'pre_mood': preMood,
      'post_mood': postMood,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
