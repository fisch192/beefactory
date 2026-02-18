class SiteModel {
  final int? id;
  final String? serverId;
  final String name;
  final String? location;
  final double? latitude;
  final double? longitude;
  final double? elevation;
  final String? notes;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Transient field for UI
  int hiveCount;

  SiteModel({
    this.id,
    this.serverId,
    required this.name,
    this.location,
    this.latitude,
    this.longitude,
    this.elevation,
    this.notes,
    this.syncStatus = 'pending',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.hiveCount = 0,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      id: json['id'] as int?,
      serverId: json['server_id'] as String? ?? json['id']?.toString(),
      name: json['name'] as String? ?? '',
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      elevation: (json['elevation'] as num?)?.toDouble(),
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
      'name': name,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'elevation': elevation,
      'notes': notes,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SiteModel copyWith({
    int? id,
    String? serverId,
    String? name,
    String? location,
    double? latitude,
    double? longitude,
    double? elevation,
    String? notes,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? hiveCount,
  }) {
    return SiteModel(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      elevation: elevation ?? this.elevation,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hiveCount: hiveCount ?? this.hiveCount,
    );
  }
}
