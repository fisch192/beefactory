class TaskModel {
  final int? id;
  final String? serverId;
  final String clientTaskId;
  final int? hiveId;
  final int? siteId;
  final String title;
  final String? description;
  final String status;
  final DateTime? dueAt;
  final int? recurDays;
  final String source;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskModel({
    this.id,
    this.serverId,
    required this.clientTaskId,
    this.hiveId,
    this.siteId,
    required this.title,
    this.description,
    this.status = 'open',
    this.dueAt,
    this.recurDays,
    this.source = 'manual',
    this.syncStatus = 'pending',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isOverdue {
    if (dueAt == null || status == 'done') return false;
    return dueAt!.isBefore(DateTime.now());
  }

  bool get isDueToday {
    if (dueAt == null) return false;
    final now = DateTime.now();
    return dueAt!.year == now.year &&
        dueAt!.month == now.month &&
        dueAt!.day == now.day;
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as int?,
      serverId: json['server_id'] as String? ?? json['id']?.toString(),
      clientTaskId: json['client_task_id'] as String? ?? '',
      hiveId: json['hive_id'] as int?,
      siteId: json['site_id'] as int?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'open',
      dueAt: json['due_at'] != null
          ? DateTime.tryParse(json['due_at'] as String)
          : null,
      recurDays: json['recur_days'] as int?,
      source: json['source'] as String? ?? 'manual',
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
      'client_task_id': clientTaskId,
      'hive_id': hiveId,
      'site_id': siteId,
      'title': title,
      'description': description,
      'status': status,
      'due_at': dueAt?.toUtc().toIso8601String(),
      'recur_days': recurDays,
      'source': source,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TaskModel copyWith({
    int? id,
    String? serverId,
    String? clientTaskId,
    int? hiveId,
    int? siteId,
    String? title,
    String? description,
    String? status,
    DateTime? dueAt,
    int? recurDays,
    String? source,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      clientTaskId: clientTaskId ?? this.clientTaskId,
      hiveId: hiveId ?? this.hiveId,
      siteId: siteId ?? this.siteId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      dueAt: dueAt ?? this.dueAt,
      recurDays: recurDays ?? this.recurDays,
      source: source ?? this.source,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
