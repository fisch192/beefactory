class HiveModel {
  final int? id;
  final String? serverId;
  final int siteId;
  final int number;
  final String? name;
  final int? queenYear;
  final String? queenColor;
  final bool queenMarked;
  final String? notes;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  HiveModel({
    this.id,
    this.serverId,
    required this.siteId,
    required this.number,
    this.name,
    this.queenYear,
    this.queenColor,
    this.queenMarked = false,
    this.notes,
    this.syncStatus = 'pending',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory HiveModel.fromJson(Map<String, dynamic> json) {
    return HiveModel(
      id: json['id'] as int?,
      serverId: json['server_id'] as String? ?? json['id']?.toString(),
      siteId: json['site_id'] as int? ?? 0,
      number: json['number'] as int? ?? 0,
      name: json['name'] as String?,
      queenYear: json['queen_year'] as int?,
      queenColor: json['queen_color'] as String?,
      queenMarked: json['queen_marked'] as bool? ?? false,
      notes: json['notes'] as String?,
      syncStatus: json['sync_status'] as String? ?? 'uploaded',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      'site_id': siteId,
      'number': number,
      'name': name,
      'queen_year': queenYear,
      'queen_color': queenColor,
      'queen_marked': queenMarked,
      'notes': notes,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  HiveModel copyWith({
    int? id,
    String? serverId,
    int? siteId,
    int? number,
    String? name,
    int? queenYear,
    String? queenColor,
    bool? queenMarked,
    String? notes,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HiveModel(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      siteId: siteId ?? this.siteId,
      number: number ?? this.number,
      name: name ?? this.name,
      queenYear: queenYear ?? this.queenYear,
      queenColor: queenColor ?? this.queenColor,
      queenMarked: queenMarked ?? this.queenMarked,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName => name ?? 'Hive #$number';
}
