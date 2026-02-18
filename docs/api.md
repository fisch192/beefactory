# API Documentation

Base URL: `http://localhost:3000/v1`

All endpoints return JSON. Errors follow format: `{ statusCode, message, error }`.

## Authentication

All endpoints require `Authorization: Bearer <accessToken>` except:
- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/refresh`
- `GET /zones`
- `GET /zones/weekly-focus`

### POST /v1/auth/register

Register a new user.

**Body:**
```json
{
  "email": "user@example.com",
  "password": "min8chars",
  "displayName": "Max Imker"
}
```

**Response 201:**
```json
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "displayName": "Max Imker",
    "role": "USER"
  }
}
```

### POST /v1/auth/login

**Body:** `{ "email": "...", "password": "..." }`

**Response 200:** Same as register response.

### POST /v1/auth/refresh

**Body:** `{ "refreshToken": "eyJ..." }`

**Response 200:** `{ "accessToken": "...", "refreshToken": "..." }`

### POST /v1/auth/logout

**Response 200:** `{ "message": "Logged out" }`

---

## Sites

### GET /v1/sites

List user's sites (excludes soft-deleted).

**Response 200:** `Site[]`

### POST /v1/sites

**Body:**
```json
{
  "name": "Obstwiese Meran",
  "location": "Meran, Südtirol",
  "latitude": 46.6713,
  "longitude": 11.1545,
  "elevation": 300,
  "notes": "Sonniger Standort"
}
```

### PUT /v1/sites/:id

Update site. Body same as create (all fields optional).

### DELETE /v1/sites/:id

Soft delete (sets deletedAt).

---

## Hives

### GET /v1/hives?siteId=uuid

List hives, optionally filtered by site.

### POST /v1/hives

**Body:**
```json
{
  "siteId": "uuid",
  "number": 1,
  "name": "Volk 1",
  "queenYear": 2024,
  "queenColor": "blue",
  "queenMarked": true
}
```

### PUT /v1/hives/:id

### DELETE /v1/hives/:id

---

## Events

### POST /v1/events

Create event. **Idempotent** — if `clientEventId` already exists for this user, returns existing event (200 instead of 201).

**Body:**
```json
{
  "clientEventId": "client-generated-uuid",
  "siteId": "uuid",
  "hiveId": "uuid (optional)",
  "type": "INSPECTION",
  "occurredAtLocal": "2024-06-15T10:00:00+02:00",
  "occurredAtUtc": "2024-06-15T08:00:00.000Z",
  "payload": { "brood": "compact", "queenSeen": true },
  "attachments": [],
  "source": "MANUAL"
}
```

**Event types:** INSPECTION, VARROA_MEASUREMENT, TREATMENT, FEEDING, HARVEST, NOTE, TASK_CREATED, TASK_DONE, COMMUNITY_IMPORT, DELETE

**Source types:** MANUAL, VOICE, COMMUNITY, RULE

### GET /v1/events

**Query params:**
| Param | Type | Description |
|-------|------|-------------|
| siteId | UUID | Filter by site |
| hiveId | UUID | Filter by hive |
| type | EventType | Filter by type |
| since | ISO datetime | Events updated after this time (for sync) |
| limit | number | Max results (default 50, max 200) |
| cursor | string | Cursor for pagination |

**Response 200:**
```json
{
  "data": [Event],
  "cursor": "next-page-cursor",
  "hasMore": true
}
```

---

## Tasks

### POST /v1/tasks

**Body:**
```json
{
  "clientTaskId": "optional-client-uuid",
  "hiveId": "uuid (optional)",
  "siteId": "uuid (optional)",
  "title": "Varroa-Kontrolle",
  "description": "Windel einlegen und nach 48h auswerten",
  "dueAt": "2024-07-01T08:00:00.000Z",
  "recurDays": 14,
  "source": "RULE"
}
```

### GET /v1/tasks

**Query params:** `status`, `dueFrom`, `dueTo`, `since`, `limit`

### PUT /v1/tasks/:id

Update status, title, dueAt, etc.

---

## Attachments

### POST /v1/attachments/presign

Get a presigned URL to upload a file to S3/MinIO.

**Body:**
```json
{
  "filename": "inspection-photo.jpg",
  "contentType": "image/jpeg"
}
```

**Response 200:**
```json
{
  "uploadUrl": "http://localhost:9000/bee-attachments/...",
  "key": "users/uuid/2024/06/filename.jpg",
  "publicUrl": "http://localhost:9000/bee-attachments/users/..."
}
```

Client uploads file via PUT to `uploadUrl`, then references `key` in event attachments.

---

## Community

### GET /v1/community/feed

**Query params:**
| Param | Type | Description |
|-------|------|-------------|
| region | string | Required. e.g. "suedtirol" |
| elevationBand | string | Required. "low", "mid", "high" |
| limit | number | Default 20 |
| cursor | string | Pagination cursor |

**Response 200:**
```json
{
  "data": [{
    "id": "uuid",
    "title": "Schwarmstimmung",
    "body": "Hat jemand schon Schwarmzellen?",
    "tags": ["schwarm"],
    "photoUrls": [],
    "createdAt": "...",
    "user": { "id": "uuid", "displayName": "Max" },
    "commentCount": 3
  }],
  "cursor": "...",
  "hasMore": false
}
```

### POST /v1/community/posts

**Body:**
```json
{
  "region": "suedtirol",
  "elevationBand": "low",
  "title": "Schwarmstimmung",
  "body": "Hat jemand schon Schwarmzellen gefunden?",
  "tags": ["schwarm", "frühling"],
  "photoUrls": []
}
```

Rate limited: max 10 posts per hour per user.

### GET /v1/community/posts/:id

Returns post with comments.

### POST /v1/community/posts/:id/comments

**Body:** `{ "body": "Ja, bei mir auch!", "photoUrl": "optional" }`

### POST /v1/community/posts/:id/report

**Body:** `{ "reason": "Spam" }`

### POST /v1/community/comments/:id/report

**Body:** `{ "reason": "Inappropriate" }`

---

## Zones

### GET /v1/zones

Returns all available zone profiles (no auth required).

**Response 200:**
```json
[{
  "id": "uuid",
  "region": "suedtirol",
  "elevationBand": "low",
  "seasonStartMonth": 3,
  "seasonStartDay": 1
}]
```

### GET /v1/zones/weekly-focus

**Query params:** `region`, `elevationBand`, `week` (1-52)

**Response 200:**
```json
{
  "week": 24,
  "region": "suedtirol",
  "elevationBand": "low",
  "title_de": "Honigernte vorbereiten",
  "title_it": "Preparare la raccolta del miele",
  "tips_de": ["Honigfeuchte prüfen", "Schleuderraum vorbereiten"],
  "tips_it": ["Verificare l'umidità del miele", "Preparare la sala di smielatura"]
}
```

---

## Export

### POST /v1/export

**Body:** `{ "format": "csv", "siteId": "optional", "from": "optional", "to": "optional" }`

**Response 200:** `{ "downloadUrl": "signed-url" }`

MVP returns CSV of events.
