# Data Model

## Entity Relationship

```
User 1──N Site 1──N Hive
  │         │         │
  │         │         │
  N         N         N
Event ──────┘─────────┘
  │
Task
  │
CommunityPost 1──N CommunityComment
  │                      │
  N                      N
Report ──────────────────┘

ZoneProfile (standalone reference data)
```

## Core Entities

### User
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | PK |
| email | VARCHAR | Unique |
| password_hash | VARCHAR | bcrypt |
| display_name | VARCHAR | Optional |
| role | ENUM | USER, MODERATOR, ADMIN |
| region | VARCHAR | e.g. "suedtirol" |
| elevation_band | VARCHAR | low, mid, high |
| language | VARCHAR | de, it |
| fcm_token | VARCHAR | Push notification token |

### Site (Standort)
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK → users |
| name | VARCHAR | e.g. "Obstwiese Meran" |
| location | VARCHAR | Human-readable |
| latitude | FLOAT | Optional, private |
| longitude | FLOAT | Optional, private |
| elevation | INT | Meters |
| notes | TEXT | |

### Hive (Volk)
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | PK |
| user_id | UUID | FK → users |
| site_id | UUID | FK → sites |
| number | INT | Hive number at site |
| name | VARCHAR | Optional nickname |
| queen_year | INT | Year queen was born |
| queen_color | VARCHAR | Marking color |
| queen_marked | BOOL | |

### Event (Universal Event Log)
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | PK, server-assigned |
| client_event_id | VARCHAR | Client UUID for idempotency |
| user_id | UUID | FK → users |
| hive_id | UUID | FK → hives, nullable for site-level |
| site_id | UUID | FK → sites |
| type | ENUM | See Event Types |
| occurred_at_local | VARCHAR | ISO string with local TZ |
| occurred_at_utc | TIMESTAMP | UTC for sorting/sync |
| payload | JSONB | Type-specific data |
| attachments | JSONB | Array of {key, type, url} |
| source | ENUM | MANUAL, VOICE, COMMUNITY, RULE |

**Unique constraint**: (user_id, client_event_id) — enables idempotent sync.

## Event Types & Payloads

### INSPECTION
```json
{
  "brood": "present|compact|patchy|none",
  "queenSeen": true,
  "queenCells": "none|cups|charged",
  "temperament": "calm|normal|defensive",
  "stores": "low|medium|high",
  "supers": "added|removed|none",
  "notes": "Free text"
}
```

### VARROA_MEASUREMENT
```json
{
  "method": "sticky_board|alcohol_wash|sugar_roll|co2",
  "durationHours": 48,
  "mitesCount": 12,
  "normalizedRate": 6.0,
  "notes": ""
}
```

### TREATMENT
```json
{
  "method": "formic|oxalic|thymol|biotech|brood_break",
  "dosage": "2ml per Wabengasse",
  "startDate": "2024-08-01",
  "endDate": "2024-08-14",
  "notes": ""
}
```

### FEEDING
```json
{
  "feedType": "syrup|candy|sugar",
  "amount": 6.0,
  "unit": "kg|l",
  "notes": ""
}
```

### HARVEST
```json
{
  "amount": 12.5,
  "unit": "kg",
  "honeyType": "Blütenhonig",
  "supers_removed": 2,
  "notes": ""
}
```

### NOTE
```json
{
  "text": "Free text note",
  "transcript": "Original voice transcript if from voice",
  "parsedHints": {}
}
```

### COMMUNITY_IMPORT
```json
{
  "sourcePostId": "uuid",
  "sourceCommentId": "uuid",
  "importedAs": "NOTE|TASK|TREATMENT",
  "createdEventId": "uuid"
}
```

## Sync State (Client-Side Only)

Each entity in local SQLite has:
| Field | Type | Notes |
|-------|------|-------|
| sync_status | TEXT | pending, uploaded, failed |
| server_id | TEXT | UUID from server after sync |
| last_error | TEXT | Error message if failed |

## Indexes

- `events(user_id, occurred_at_utc)` — timeline queries
- `events(hive_id, occurred_at_utc)` — hive timeline
- `events(site_id, occurred_at_utc)` — site timeline
- `events(user_id, updated_at)` — incremental sync
- `events(user_id, client_event_id)` — idempotency UNIQUE
- `tasks(user_id, status)` — active tasks
- `tasks(user_id, due_at)` — upcoming tasks
- `community_posts(region, elevation_band, created_at)` — feed queries
