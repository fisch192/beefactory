# Bee - Perfect Beekeeping App

Offline-first beekeeping diary with voice entry, varroa management, community feed, and zone-based suggestions. Built for South Tyrol beekeepers (DE/IT bilingual).

## Features

- **Offline-first diary** (Stockkarte) with fast inspection capture
- **Voice entry**: dictation notes + structured command parsing (DE/IT)
- **Varroa module**: measurements, treatments, threshold alerts
- **Tasks & reminders** with push notifications
- **Community feed**: zone-based forum with post/comment/import
- **Zone logic**: weekly focus and rule-based suggestions for Südtirol
- **Analytics**: per-hive and per-site dashboards

## Quick Start

### Prerequisites

- Docker & Docker Compose
- Node.js 20+
- Flutter SDK 3.22+
- Android Studio or Xcode (for mobile)

### 1. Start Infrastructure

```bash
cd infra
docker-compose up -d
```

This starts:
- PostgreSQL 16 on port 5432
- MinIO (S3) on port 9000 (console: 9001)

### 2. Start Backend

```bash
cd services/api_backend

# Install dependencies
npm install

# Run database migrations
npx prisma migrate dev

# Generate Prisma client
npx prisma generate

# Seed demo data
npx prisma db seed

# Start dev server
npm run start:dev
```

Backend runs at http://localhost:3000

Swagger docs at http://localhost:3000/api

### 3. Start Flutter App

```bash
cd apps/mobile_flutter

# Install dependencies
flutter pub get

# Generate Drift database code
dart run build_runner build --delete-conflicting-outputs

# Run on device/emulator
flutter run
```

### 4. Default Credentials

| Service | Credentials |
|---------|------------|
| API Demo User | demo@bee.app / demo1234 |
| PostgreSQL | bee / bee_dev_pass |
| MinIO | minioadmin / minioadmin |

## Project Structure

```
bee/
├── apps/
│   └── mobile_flutter/       # Flutter app (iOS + Android)
├── services/
│   └── api_backend/          # NestJS REST API
├── infra/
│   └── docker-compose.yml    # Dev infrastructure
└── docs/
    ├── architecture.md       # System architecture
    ├── data-model.md         # Database schema & event types
    ├── sync.md               # Offline sync protocol
    └── api.md                # API documentation
```

## API Quick Reference

```bash
# Register
curl -X POST http://localhost:3000/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@bee.app","password":"test1234","displayName":"Test"}'

# Login
curl -X POST http://localhost:3000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@bee.app","password":"demo1234"}'
# Returns: { accessToken, refreshToken, user }

# Create site (use accessToken from login)
curl -X POST http://localhost:3000/v1/sites \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <accessToken>" \
  -d '{"name":"Obstwiese Meran","location":"Meran","elevation":300}'

# Create hive
curl -X POST http://localhost:3000/v1/hives \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <accessToken>" \
  -d '{"siteId":"<siteId>","number":1,"name":"Volk 1"}'

# Create inspection event
curl -X POST http://localhost:3000/v1/events \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <accessToken>" \
  -d '{
    "clientEventId":"'$(uuidgen)'",
    "siteId":"<siteId>",
    "hiveId":"<hiveId>",
    "type":"INSPECTION",
    "occurredAtLocal":"2024-06-15T10:00:00+02:00",
    "occurredAtUtc":"2024-06-15T08:00:00Z",
    "payload":{"brood":"compact","queenSeen":true,"temperament":"calm","stores":"medium"},
    "source":"MANUAL"
  }'

# Get events (with sync)
curl "http://localhost:3000/v1/events?siteId=<siteId>&limit=20" \
  -H "Authorization: Bearer <accessToken>"

# Get weekly focus
curl "http://localhost:3000/v1/zones/weekly-focus?region=suedtirol&elevationBand=low&week=24"

# Community: create post
curl -X POST http://localhost:3000/v1/community/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <accessToken>" \
  -d '{"region":"suedtirol","elevationBand":"low","title":"Schwarmstimmung","body":"Hat jemand schon Schwarmzellen gefunden?","tags":["schwarm","frühling"]}'

# Community: get feed
curl "http://localhost:3000/v1/community/feed?region=suedtirol&elevationBand=low&limit=10" \
  -H "Authorization: Bearer <accessToken>"
```

## Running Tests

```bash
# Backend unit tests
cd services/api_backend
npm run test

# Backend e2e tests (requires running postgres)
npm run test:e2e

# Flutter tests
cd apps/mobile_flutter
flutter test

# Voice parser tests specifically
flutter test test/voice_parser_test.dart

# Rule engine tests
flutter test test/rule_engine_test.dart
```

## Environment Variables

### Backend (.env)

| Variable | Default | Description |
|----------|---------|-------------|
| DATABASE_URL | postgresql://bee:bee_dev_pass@localhost:5432/bee | Postgres connection |
| JWT_SECRET | dev-jwt-secret... | Access token signing key |
| JWT_REFRESH_SECRET | dev-jwt-refresh... | Refresh token signing key |
| JWT_EXPIRY | 15m | Access token TTL |
| JWT_REFRESH_EXPIRY | 7d | Refresh token TTL |
| MINIO_ENDPOINT | localhost | S3 host |
| MINIO_PORT | 9000 | S3 port |
| MINIO_ACCESS_KEY | minioadmin | S3 access key |
| MINIO_SECRET_KEY | minioadmin | S3 secret key |
| MINIO_BUCKET | bee-attachments | S3 bucket name |
| PORT | 3000 | API server port |

## Voice Commands (Examples)

### German
- `"Notiz zu Volk 7: Brutbild gut, 2 Spielnäpfchen"` → NOTE event
- `"Volk 7 Varroa 3 pro Tag Windel 48 Stunden"` → VARROA_MEASUREMENT
- `"Volk 2 Fütterung 6 Kilo Sirup heute"` → FEEDING event
- `"Erinnerung Oxalsäure in 14 Tagen"` → TASK (reminder)
- `"Stand Meran Kontrolle nächste Woche"` → SITE_TASK

### Italian
- `"Nota per alveare 7: covata buona"` → NOTE event
- `"Alveare 7 varroa 3 al giorno tavoletta 48 ore"` → VARROA_MEASUREMENT
- `"Alveare 2 nutrizione 6 chili sciroppo oggi"` → FEEDING event
- `"Promemoria acido ossalico tra 14 giorni"` → TASK (reminder)
- `"Apiario Merano controllo la prossima settimana"` → SITE_TASK

## License

Private - All rights reserved.
