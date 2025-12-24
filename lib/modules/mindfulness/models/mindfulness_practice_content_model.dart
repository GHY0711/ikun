class MindfulnessPracticeContent {
  final String id;
  final String practiceId;
  final String contentType;
  final String? audioPath;
  final String? videoPath;
  final String? textContent;
  final Map<String, dynamic>? breathingConfig;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MindfulnessPracticeContent({
    required this.id,
    required this.practiceId,
    required this.contentType,
    this.audioPath,
    this.videoPath,
    this.textContent,
    this.breathingConfig,
    required this.sortOrder,
    this.createdAt,
    this.updatedAt,
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

  static Map<String, dynamic>? _toMap(dynamic v) {
    if (v == null) return null;
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return null;
  }

  factory MindfulnessPracticeContent.fromMap(Map<String, dynamic> map) {
    return MindfulnessPracticeContent(
      id: map['mind_content_id'].toString(),
      practiceId: map['mind_practice_id'].toString(),
      contentType: (map['content_type'] ?? '').toString(),
      audioPath: map['audio_path']?.toString(),
      videoPath: map['video_path']?.toString(),
      textContent: map['text_content']?.toString(),
      breathingConfig: _toMap(map['breathing_config']),
      sortOrder: _toInt(map['sort_order'], fallback: 1),
      createdAt: _toDateTime(map['created_at']),
      updatedAt: _toDateTime(map['update_at'] ?? map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mind_content_id': id,
      'mind_practice_id': practiceId,
      'content_type': contentType,
      'audio_path': audioPath,
      'video_path': videoPath,
      'text_content': textContent,
      'breathing_config': breathingConfig,
      'sort_order': sortOrder,
      'created_at': createdAt?.toIso8601String(),
      'update_at': updatedAt?.toIso8601String(),
    };
  }
}
