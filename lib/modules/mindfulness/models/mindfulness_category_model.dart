class MindfulnessCategory {
  final String id;
  final String name;
  final String? description;
  final String? iconPath;
  final bool isActive;
  final DateTime? createdAt;

  const MindfulnessCategory({
    required this.id,
    required this.name,
    this.description,
    this.iconPath,
    required this.isActive,
    this.createdAt,
  });

  static bool _toBool(dynamic v, {bool fallback = false}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    if (v is num) return v != 0;
    return fallback;
  }

  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  factory MindfulnessCategory.fromMap(Map<String, dynamic> map) {
    return MindfulnessCategory(
      id: map['mind_category_id'].toString(),
      name: (map['mind_name'] ?? '').toString(),
      description: map['description']?.toString(),
      iconPath: map['icon_path']?.toString(),
      isActive: _toBool(map['is_active'], fallback: true),
      createdAt: _toDateTime(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mind_category_id': id,
      'mind_name': name,
      'description': description,
      'icon_path': iconPath,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
