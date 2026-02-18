# Bee App Architecture

## Overview

Offline-first beekeeping diary with structured events, voice entry, varroa management, community feed, and zone-based suggestions.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter (Dart), Drift (SQLite), Provider |
| Backend | NestJS (TypeScript), Prisma ORM |
| Database | PostgreSQL 16 |
| Storage | MinIO (S3-compatible) |
| Auth | JWT (access + refresh tokens) |
| Push | Firebase Cloud Messaging |

## Architecture Layers

### Flutter (Clean Architecture)

```
lib/
├── core/              # Constants, errors, network utils
├── data/
│   ├── local/         # Drift DB, DAOs
│   ├── remote/        # REST API clients
│   └── sync/          # Sync engine
├── domain/
│   ├── models/        # Domain entities
│   ├── repositories/  # Abstract + impl
│   ├── rules/         # Rule engine
│   └── voice/         # Voice parser
├── presentation/
│   ├── screens/       # UI screens
│   ├── providers/     # State management
│   └── widgets/       # Reusable widgets
└── l10n/              # DE/IT translations
```

### Backend (Module Architecture)

```
src/
├── auth/          # JWT auth, register/login
├── sites/         # Site CRUD
├── hives/         # Hive CRUD
├── events/        # Event log (idempotent)
├── tasks/         # Tasks & reminders
├── community/     # Feed, posts, comments
├── zones/         # Zone profiles, weekly focus
├── attachments/   # S3 presigned URLs
├── prisma/        # DB service
└── common/        # Shared DTOs, filters
```

## Data Flow

### Offline-First Pattern

```
User Action → Local DB (immediate) → Sync Queue → Backend API
                                                       ↓
                                                  PostgreSQL
```

1. All writes go to local SQLite first
2. Sync queue tracks pending operations
3. Sync engine uploads when online
4. Downloads pull incremental changes via `since` param

### Event Sourcing (Lite)

Events are the core data model. All diary entries (inspections, measurements, treatments, feeding, harvests, notes) are stored as typed events with JSONB payloads.

Events are **immutable** - edits create new amendment events, deletes are tombstones.

### Sync Protocol

```
Client                          Server
  |-- POST /events ------------>|  (idempotent via clientEventId)
  |-- POST /attachments/presign>|  (get upload URL)
  |-- PUT  <presigned-url> ---->|  (upload to MinIO)
  |-- GET /events?since=T ----->|  (pull new events)
  |<---- events[] ------------- |
```

## Voice Entry Pipeline

```
Microphone → STT Plugin → Raw Text → VoiceParser → ParsedIntent
                                                        ↓
                                          Confidence >= 0.6?
                                         /              \
                                       Yes               No
                                        ↓                ↓
                                  Confirmation UI    Save as NOTE
                                        ↓            + "Convert?" prompt
                                  Create Event
```

## Rule Engine

Deterministic rules evaluate weekly based on:
- Zone profile (region, elevation band)
- Recent events (last 30 days)
- Current week of year
- Season configuration

Output: prioritized suggestions that can become tasks.

## Security

- JWT access tokens (15 min) + refresh tokens (7 days)
- All API endpoints require auth except `/auth/*` and `/zones/*`
- Community posts use coarse location only (region + elevation band)
- Rate limiting on community endpoints
- GDPR: account deletion endpoint, no exact GPS in public data
