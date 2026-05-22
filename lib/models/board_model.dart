class Board {
  final String id;
  final String name;
  final String slug;
  final String type; // 'SBC' or 'MC'
  final String description;
  final List<String> category;
  final List<String> bestFor;
  final List<String> alternatives;
  final String? photoFrontId;
  final String? pinDiagramId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Board({
    required this.id,
    required this.name,
    required this.slug,
    required this.type,
    required this.description,
    required this.category,
    required this.bestFor,
    required this.alternatives,
    this.photoFrontId,
    this.pinDiagramId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor to create Board from JSON
  factory Board.fromJson(Map<String, dynamic> json) {
    String? safeString(dynamic v) => v == null ? null : v.toString();

    List<String> safeList(dynamic v) {
      if (v == null) return <String>[];
      if (v is List)
        return v
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      return <String>[];
    }

    DateTime safeDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) {
        final parsed = DateTime.tryParse(v);
        if (parsed != null) return parsed;
        // try parse as int string
        final asInt = int.tryParse(v);
        if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
      }
      return DateTime.now();
    }

    return Board(
      id: safeString(json['id']) ?? '',
      name: safeString(json['name']) ?? 'Unknown',
      slug: safeString(json['slug']) ?? '',
      type: safeString(json['type']) ?? 'SBC',
      description: safeString(json['description']) ?? '',
      category: safeList(json['category']),
      bestFor: safeList(json['bestFor']),
      alternatives: safeList(json['alternatives']),
      photoFrontId: safeString(json['photoFrontId']),
      pinDiagramId: safeString(json['pinDiagramId']),
      createdAt: safeDate(json['createdAt']),
      updatedAt: safeDate(json['updatedAt']),
    );
  }

  /// Convert Board to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'type': type,
      'description': description,
      'category': category,
      'bestFor': bestFor,
      'alternatives': alternatives,
      'photoFrontId': photoFrontId,
      'pinDiagramId': pinDiagramId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of Board with optional field replacements
  Board copyWith({
    String? id,
    String? name,
    String? slug,
    String? type,
    String? description,
    List<String>? category,
    List<String>? bestFor,
    List<String>? alternatives,
    String? photoFrontId,
    String? pinDiagramId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Board(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      type: type ?? this.type,
      description: description ?? this.description,
      category: category ?? this.category,
      bestFor: bestFor ?? this.bestFor,
      alternatives: alternatives ?? this.alternatives,
      photoFrontId: photoFrontId ?? this.photoFrontId,
      pinDiagramId: pinDiagramId ?? this.pinDiagramId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Board(id: $id, name: $name, type: $type)';
  }
}
