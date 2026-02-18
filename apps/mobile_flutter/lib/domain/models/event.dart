import 'dart:convert';

enum EventType {
  inspection,
  feeding,
  treatment,
  harvest,
  swarm,
  queenEvent,
  loss,
  split,
  combine,
  note,
  other;

  String get label {
    switch (this) {
      case EventType.inspection:
        return 'Inspection';
      case EventType.feeding:
        return 'Feeding';
      case EventType.treatment:
        return 'Treatment';
      case EventType.harvest:
        return 'Harvest';
      case EventType.swarm:
        return 'Swarm';
      case EventType.queenEvent:
        return 'Queen Event';
      case EventType.loss:
        return 'Loss';
      case EventType.split:
        return 'Split';
      case EventType.combine:
        return 'Combine';
      case EventType.note:
        return 'Note';
      case EventType.other:
        return 'Other';
    }
  }

  static EventType fromString(String value) {
    return EventType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EventType.other,
    );
  }
}

class EventModel {
  final int? id;
  final String? serverId;
  final String clientEventId;
  final int? hiveId;
  final int? siteId;
  final EventType type;
  final DateTime occurredAtLocal;
  final DateTime occurredAtUtc;
  final Map<String, dynamic> payload;
  final List<String>? attachments;
  final String source;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    this.id,
    this.serverId,
    required this.clientEventId,
    this.hiveId,
    this.siteId,
    required this.type,
    required this.occurredAtLocal,
    required this.occurredAtUtc,
    this.payload = const {},
    this.attachments,
    this.source = 'manual',
    this.syncStatus = 'pending',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final payloadRaw = json['payload'];
    Map<String, dynamic> payloadMap;
    if (payloadRaw is String) {
      try {
        payloadMap = jsonDecode(payloadRaw) as Map<String, dynamic>;
      } catch (_) {
        payloadMap = {};
      }
    } else if (payloadRaw is Map<String, dynamic>) {
      payloadMap = payloadRaw;
    } else {
      payloadMap = {};
    }

    final attachRaw = json['attachments'];
    List<String>? attachList;
    if (attachRaw is String && attachRaw.isNotEmpty) {
      try {
        attachList = (jsonDecode(attachRaw) as List).cast<String>();
      } catch (_) {
        attachList = [attachRaw];
      }
    } else if (attachRaw is List) {
      attachList = attachRaw.cast<String>();
    }

    return EventModel(
      id: json['id'] as int?,
      serverId: json['server_id'] as String? ?? json['id']?.toString(),
      clientEventId: json['client_event_id'] as String? ?? '',
      hiveId: json['hive_id'] as int?,
      siteId: json['site_id'] as int?,
      type: EventType.fromString(json['type'] as String? ?? 'other'),
      occurredAtLocal: DateTime.tryParse(
              json['occurred_at_local'] as String? ?? '') ??
          DateTime.now(),
      occurredAtUtc:
          DateTime.tryParse(json['occurred_at_utc'] as String? ?? '') ??
              DateTime.now().toUtc(),
      payload: payloadMap,
      attachments: attachList,
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
      'client_event_id': clientEventId,
      'hive_id': hiveId,
      'site_id': siteId,
      'type': type.name,
      'occurred_at_local': occurredAtLocal.toIso8601String(),
      'occurred_at_utc': occurredAtUtc.toUtc().toIso8601String(),
      'payload': jsonEncode(payload),
      'attachments':
          attachments != null ? jsonEncode(attachments) : null,
      'source': source,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get payloadString => jsonEncode(payload);

  EventModel copyWith({
    int? id,
    String? serverId,
    String? clientEventId,
    int? hiveId,
    int? siteId,
    EventType? type,
    DateTime? occurredAtLocal,
    DateTime? occurredAtUtc,
    Map<String, dynamic>? payload,
    List<String>? attachments,
    String? source,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      clientEventId: clientEventId ?? this.clientEventId,
      hiveId: hiveId ?? this.hiveId,
      siteId: siteId ?? this.siteId,
      type: type ?? this.type,
      occurredAtLocal: occurredAtLocal ?? this.occurredAtLocal,
      occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
      payload: payload ?? this.payload,
      attachments: attachments ?? this.attachments,
      source: source ?? this.source,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
