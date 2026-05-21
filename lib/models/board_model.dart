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
    return Board(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      slug: json['slug'] as String? ?? '',
      type: json['type'] as String? ?? 'SBC',
      description: json['description'] as String? ?? '',
      category: List<String>.from(json['category'] as List? ?? []),
      bestFor: List<String>.from(json['bestFor'] as List? ?? []),
      alternatives: List<String>.from(json['alternatives'] as List? ?? []),
      photoFrontId: json['photoFrontId'] as String?,
      pinDiagramId: json['pinDiagramId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
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
