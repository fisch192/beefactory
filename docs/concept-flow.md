# BEE FACTORY — Concept Flow

## System Overview

```
┌───────────────────────────────────────────────────────────────────────┐
│                         BEE FACTORY ECOSYSTEM                         │
│                                                                       │
│  ┌───────────────┐   ┌───────────────┐   ┌─────────────────────────┐ │
│  │  Mobile App    │   │   Website     │   │      Backend API        │ │
│  │  (Flutter)     │   │   (Astro)     │   │      (NestJS)           │ │
│  │               │   │               │   │                         │ │
│  │ Android/iOS   │   │ beefactory    │   │  REST API /v1/*         │ │
│  │ Offline-first │   │ .it/.de       │   │  WebSocket /chat (live) │ │
│  │ SQLite local  │   │ Vercel        │   │  JWT Auth               │ │
│  │ Voice DE/IT   │   │ Three.js      │   │  Prisma + PostgreSQL    │ │
│  │ Socket.IO     │   │ splash anim.  │   │  MinIO attachments      │ │
│  └───────┬───────┘   └───────────────┘   └──────────┬──────────────┘ │
│          │                                          │                 │
│          │      HTTPS REST + WSS Socket.IO          │                 │
│          └──────────────────────────────────────────┘                 │
│                             │                                         │
│             ┌───────────────┼────────────────┐                        │
│             │               │                │                        │
│        ┌────▼──────┐  ┌─────▼───────┐  ┌────▼───────┐               │
│        │PostgreSQL  │  │    MinIO    │  │   Zones    │               │
│        │  16        │  │  (S3 files) │  │  Config    │               │
│        └───────────┘  └────────────┘  └────────────┘               │
└───────────────────────────────────────────────────────────────────────┘
```

---

## 0. Status & Conventions

- Values (ports, TTLs, rate limits) are **examples** unless marked "current".
- API routes: `METHOD /v1/resource/...`. In tables, paths are relative to the resource prefix.
- Refresh tokens must go to **secure storage** (Keychain/Keystore). `SharedPreferences` is for non-sensitive prefs only.
- Events are **append-only** and idempotent via `clientEventId`.
- Mutable entities (sites/hives/tasks) use soft-delete patterns.

---

## 1. User Journey

```
    ┌─────────────┐
    │  App Launch  │
    └──────┬──────┘
           │
    ┌──────▼──────┐     No
    │ Onboarding  ├────────────┐
    │ complete?   │            │
    └──────┬──────┘     ┌──────▼───────────────┐
           │ Yes        │ 4 Onboarding Pages:  │
           │            │ 1. Logo + Welcome    │
           │            │ 2. Sites & Hives     │
           │            │ 3. Varroa Tracking   │
           │            │ 4. Community (login) │
           │            └──────┬───────────────┘
           │                   │ "Get Started"
           │            ┌──────▼───────────────┐
           │            │ SharedPreferences     │
           │            │ onboarding_complete=1 │
    ┌──────▼──────┐     └──────┬───────────────┘
    │             │◄───────────┘
    │  HOME SCREEN│
    │  (no login) │
    └──────┬──────┘
           │
    ┌──────▼─────────────────────────────────────────────┐
    │                    BOTTOM TABS                       │
    ├───────────┬───────────┬────────────┬────────────────┤
    │  Home     │  Sites    │ Community  │   Settings     │
    │           │           │            │                │
    │ Greeting  │ Site list │ ► LOGIN    │ Zone selection │
    │ Actions   │ ► Detail  │  REQUIRED  │ Language DE/IT │
    │ Tasks     │   ► Hives │            │ Notifications  │
    │ Summary   │           │ Feed       │ Shop link      │
    │           │           │ Comments   │ Data export    │
    │ + Voice   │           │ Report     │ Delete account │
    │   entry   │           │ Import     │                │
    └───────────┴───────────┴────────────┴────────────────┘
         │           │
    ┌────▼────┐ ┌────▼──────┐
    │ Voice   │ │ Hive      │
    │ Entry   │ │ Detail    │
    │ (DE/IT) │ ├───────────┤
    └─────────┘ │ Inspect   │
                │ Varroa    │
                │ Treatment │
                │ History   │
                │ + Photos  │
                └───────────┘
```

---

## 2. Backend API

```
┌────────────────────────────────────────────────────────────────┐
│                   NestJS Backend (port 3000)                    │
│                                                                │
│  Middleware:  CORS ─ ThrottlerGuard (60/min) ─ ExceptionFilter │
│  Auth:       JWT Bearer  (access 15m / refresh 7d)             │
│                                                                │
│  /v1/auth (public)         /v1/sites (auth)                    │
│  ├ POST /register          ├ GET /                             │
│  ├ POST /login             ├ POST /                            │
│  ├ POST /refresh           ├ GET /:id                          │
│  └ POST /logout            ├ PUT /:id                          │
│                            └ DELETE /:id  (soft, deletedAt)    │
│                                                                │
│  /v1/hives (auth)          /v1/events (auth)                   │
│  ├ GET /?siteId=           ├ POST /  (idempotent, clientId)    │
│  ├ POST /                  └ GET /   (?since=ts, cursor)       │
│  ├ GET /:id                                                    │
│  ├ PUT /:id                /v1/tasks (auth)                    │
│  └ DELETE /:id (soft)      ├ POST /                            │
│                            ├ GET /   (?status, cursor)         │
│  /v1/community (auth)      ├ GET /:id                          │
│  ├ GET /posts  (feed)      ├ PUT /:id                          │
│  ├ POST /posts             └ DELETE /:id (→ CANCELLED)         │
│  ├ GET /posts/:id                                              │
│  ├ POST /comments          /v1/zones (public)                  │
│  └ POST /reports           ├ GET /                             │
│                            └ GET /weekly-focus                  │
│  /v1/attachments (auth)                                        │
│  └ POST /presign  → MinIO presigned URL                        │
│                                                                │
│  Prisma ORM → PostgreSQL 16                                    │
│  Tables: User, Site, Hive, Event, Task, CommunityPost,         │
│          CommunityComment, Report, ZoneProfile,                 │
│          Channel, Topic, Message                                │
└────────────────────────────────────────────────────────────────┘
```

---

## 3. Flutter App Architecture

```
┌─────────────────────── PRESENTATION ──────────────────────────┐
│  Screens          Providers        Widgets          Router     │
│  ──────           ─────────        ───────          ──────     │
│  Home             AuthProvider     AnimatedLogo     /onboarding│
│  Sites (+detail)  SitesProvider    PhotoPicker      /home      │
│  Hives (+detail)  SyncProvider     EventTimeline    /sites     │
│  Varroa/Treat     CommunityProv   VoiceConfirm     /community │
│  Community                         QuickActions     /voice     │
│  Voice Entry                                        /settings  │
│  Settings                                           /login     │
│  Onboarding                                                    │
└───────────────────────────┬───────────────────────────────────┘
                            │
┌───────────────────────────▼──── DOMAIN ───────────────────────┐
│  Models           Repositories     Voice               Rules  │
│  ──────           ────────────     ─────               ─────  │
│  User             AuthRepo         VoiceService        Engine │
│  Site             SiteRepo         VoiceParser         Zone   │
│  Hive             HiveRepo         ParsedIntent        Config │
│  Event                             NumberWords(DE/IT)         │
│  Task                              6 intent types             │
│                                    confidence scoring         │
│                                                               │
│  Rule Engine: 6 seasonal rules                                │
│  ├ Spring inspection     ├ Swarm control                      │
│  ├ Varroa measurement    ├ Feeding check                      │
│  ├ Post-treatment check  └ Harvest readiness                  │
│  Based on: region + elevationBand + weekOfYear                │
└───────────────────────────┬───────────────────────────────────┘
                            │
┌───────────────────────────▼──── DATA ─────────────────────────┐
│  LOCAL (Drift/SQLite)              REMOTE (HTTP)              │
│  ─────────────────────             ──────────────             │
│  Sites table (syncStatus)          ApiClient (JWT auto-inject)│
│  Hives table (syncStatus)          AuthApi                    │
│  Events table (syncStatus)         SitesApi, HivesApi         │
│  Tasks table (syncStatus)          EventsApi, TasksApi        │
│  SyncQueue                         CommunityApi               │
│                                    AttachmentService          │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │                    SYNC ENGINE                           │  │
│  │  1. Write to SQLite immediately (offline-first)          │  │
│  │  2. On connectivity: upload Sites→Hives→Events→Tasks     │  │
│  │  3. Download: GET /?since=lastSync                       │  │
│  │  4. Merge server → SQLite (skip if exists)               │  │
│  │  5. Idempotency via clientEventId / clientTaskId         │  │
│  │  6. Failed items stay in queue for retry                 │  │
│  └─────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
```

---

## 4. Offline-First Sync Flow

```
USER ACTION                    LOCAL                      SERVER
    │                           │                           │
    │  "Save inspection"        │                           │
    ├──────────────────────────►│                           │
    │                           │ Write to SQLite           │
    │                           │ syncStatus = pending      │
    │                           │                           │
    │  ◄── UI updated ─────────┤                           │
    │      immediately          │                           │
    │                           │ ── Online? ──►            │
    │                    [YES]  │  POST /events             │
    │                           ├──────────────────────────►│
    │                           │      200 OK + serverId    │
    │                           │◄──────────────────────────┤
    │                           │ syncStatus = uploaded      │
    │                           │                           │
    │                           │  GET /events?since=ts     │
    │                           ├──────────────────────────►│
    │                           │      [new events]         │
    │                           │◄──────────────────────────┤
    │                           │ Merge into SQLite         │
    │                           │                           │
    │                    [NO]   │ Stay pending              │
    │                           │ Retry on reconnect        │
```

**Sync details**:
- Upload order: Sites → Hives → Events → Tasks (dependency chain)
- Events deduplicated via `clientEventId` unique constraint
- Failed uploads: `syncStatus = failed`, retried on next sync
- Download: skip if `serverId` already exists locally
- `lastSyncTime` stored in SharedPreferences

---

## 5. Authentication

- **Most features work without login** (sites, hives, varroa, voice, settings)
- **Login required only for** Community tab → redirects to `/login?redirect=/community`
- "Continue without account" button → goes to `/home`

```
Register:  POST /auth/register  {email, password, fullName, region, language}
Login:     POST /auth/login     {email, password}  → {accessToken, refreshToken}
Refresh:   POST /auth/refresh   {refreshToken}     → {accessToken, refreshToken}
Logout:    POST /auth/logout    (stateless, client clears tokens)
```

Access token: 15min, stored in memory. Refresh token: 7d, stored in secure storage.

---

## 6. Voice Entry Pipeline

```
┌──────────────┐     ┌───────────────────┐     ┌──────────────────┐
│ speech_to_text│────►│   VoiceParser     │────►│ Confirmation UI  │
│ (DE or IT)   │     │                   │     │                  │
│              │     │ 7 intent types:   │     │ Shows parsed     │
│ "Volk drei,  │     │ • note            │     │ fields + icon    │
│  Varroa 5    │     │ • varroaMeasure   │     │                  │
│  Windel 48h" │     │ • feeding         │     │ Confidence ≥ 0.6 │
│              │     │ • treatment       │     │ → confirm & save │
└──────────────┘     │ • reminder        │     │                  │
                     │ • siteTask        │     │ Confidence < 0.6 │
                     │ • inspection      │     │ → save as NOTE   │
                     │                   │     │                  │
                     │ Extracts: hiveRef,│     │ Save → SQLite    │
                     │ siteRef, date,    │     │ (offline-first)  │
                     │ quantity, method  │     │ source: voice    │
                     └───────────────────┘     └──────────────────┘
```

Supported entities: hive numbers (word + digit), quantities (kg, L), durations (hours), dates (relative: morgen, übermorgen, in X Tagen), varroa methods (Windel, Alkoholwaschung), treatment methods (Ameisensäure, Oxalsäure, Thymol), feed types (Sirup, Futterteig).

---

## 7. Community (Discord-like Channels)

Architecture: Channel → Topic → Messages (real-time via WebSocket).

```
┌──────────────────────────────────────────────────────────┐
│                    Community Flow                         │
│                                                          │
│  ┌──────────┐   ┌───────────┐   ┌──────────────────────┐│
│  │ Channels │──►│  Topics   │──►│  Real-Time Chat      ││
│  │          │   │           │   │                      ││
│  │ #general │   │ "Erste    │   │ Socket.IO WebSocket  ││
│  │ #varroa  │   │  Durch-   │   │ /chat namespace      ││
│  │ #anfänger│   │  sicht"   │   │                      ││
│  │ #ernte   │   │           │   │ Events:              ││
│  │          │   │ Pinned /  │   │  join_topic          ││
│  │ Users can│   │ Locked    │   │  send_message        ││
│  │ create   │   │ support   │   │  new_message         ││
│  │ channels │   │           │   │  typing / stop_typing││
│  └──────────┘   └───────────┘   └──────────────────────┘│
│                                                          │
│  Backend endpoints:                                      │
│  REST: /v1/channels, /v1/channels/:id/topics             │
│        /v1/channels/topics/:id/messages                  │
│  WS:   wss://host/chat (Socket.IO namespace)             │
│                                                          │
│  DB: Channel → Topic → Message                           │
│  Message supports: reply-to threading, photo, soft-delete│
└──────────────────────────────────────────────────────────┘
```

**Legacy post system** (CommunityPost/CommunityComment) still available at `/v1/community/posts`.

### Hosting (Fly.io)

```
API:       https://beefactory-api.fly.dev
Swagger:   https://beefactory-api.fly.dev/api
WebSocket: wss://beefactory-api.fly.dev/chat
DB:        Fly Postgres (Frankfurt, free tier)
```

Deploy: `cd infra && ./deploy.sh setup && ./deploy.sh deploy`

---

## 8. Event System (Universal Diary)

Every diary action = one immutable Event row. Append-only, never updated.

| Type | Payload (JSONB) |
|------|----------------|
| INSPECTION | brood, queenSeen, temperament, stores, supers |
| VARROA_MEASUREMENT | method, mitesCount, durationHours, normalizedRate |
| TREATMENT | method, dosage, notes |
| FEEDING | feedType, amount, unit |
| HARVEST | amount, unit, notes |
| NOTE | text, parsedHints |
| TASK_CREATED | title, dueAt |
| TASK_DONE | taskId |

Source: `MANUAL` | `VOICE` | `COMMUNITY` | `RULE`

Idempotency: `unique(userId, clientEventId)` — safe to retry uploads.

---

## 9. Attachment Flow

```
Flutter App                     Backend              MinIO
    │                              │                    │
    │  Pick photo (camera/gallery) │                    │
    │  image_picker, max 1920px    │                    │
    │                              │                    │
    │  POST /attachments/presign   │                    │
    ├─────────────────────────────►│                    │
    │  {filename, content_type}    │  Generate key      │
    │                              │  Presign URL       │
    │  ◄── {url, key} ────────────┤                    │
    │                              │                    │
    │  PUT url (binary upload)     │                    │
    ├──────────────────────────────┼───────────────────►│
    │                              │                    │ Store
    │                              │                    │
    │  Store key in Event.attachments JSON              │
    │  ["photos/uuid-1.jpg", "photos/uuid-2.jpg"]      │
```

PhotoPickerButton widget: camera/gallery bottom sheet, max 3 photos per event.

---

## 10. Data Export

Settings → Export Data:
- Reads all local SQLite data (sites, hives, events, tasks)
- Writes formatted JSON to app documents directory
- Shows file path in success dialog
- File: `bee_export_YYYY-MM-DDTHH-MM-SS.json`

---

## 11. Infrastructure (Docker Compose)

```
┌────────────────────────────────────────────────────────────────┐
│                      docker-compose.yml                         │
│                                                                │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌──────────┐│
│  │ PostgreSQL  │  │   MinIO    │  │ minio-init │  │ Backend  ││
│  │ :5432       │  │ :9000 API  │  │ (one-shot) │  │ :3000    ││
│  │             │  │ :9001 UI   │  │            │  │          ││
│  │ DB: bee     │  │            │  │ Creates    │  │ NestJS   ││
│  │ User: bee   │  │ minioadmin │  │ bucket:    │  │ Prisma   ││
│  │ vol: pg_data│  │ vol: minio │  │ bee-attach │  │ migrate  ││
│  │ healthcheck │  │ healthcheck│  │            │  │ deploy   ││
│  └────────────┘  └────────────┘  └────────────┘  └──────────┘│
│                                                                │
│  Backend depends_on: postgres (healthy) + minio (healthy)      │
│  Backend healthcheck: curl /v1/zones                           │
│  Dockerfile: multi-stage Node 20 Alpine build                  │
└────────────────────────────────────────────────────────────────┘
```

Environment: `.env` (local dev) / `.env.docker` (compose) with:
`DATABASE_URL`, `JWT_SECRET`, `JWT_REFRESH_SECRET`, `MINIO_*`, `PORT`

---

## 12. Website (Beefactory E-Commerce)

```
Astro + Vercel   │  Bilingual DE/IT
─────────────────┼──────────────────────────
/de/             │  /it/
├ Homepage       │  ├ Homepage
├ /kategorien/:h │  ├ /categorie/:h
├ /produkte/:h   │  ├ /prodotti/:h
├ /neuimker      │  ├ /nuovi-apicoltori
├ /ueber-uns     │  ├ /chi-siamo
├ /faq           │  ├ /faq
├ /impressum     │  ├ /impressum
├ /datenschutz   │  ├ /privacy
├ /agb           │  ├ /agb
├ /versand       │  ├ /spedizione
└ /wiederruf     │  └ /recesso

Admin panel: /admin/* (protected)
├ /admin/products      — Product CRUD
├ /admin/collections   — Category management
├ /admin/testimonials  — Review management
├ /admin/translations  — i18n strings
├ /admin/settings      — Site config
└ /admin/backup        — Data export/restore
```

Features:
- Product catalog (local JSON store, admin-editable)
- Shopping cart (Preact island: CartDrawer)
- Three.js welcome splash (first visit, sessionStorage)
- Three.js hero scene (honeycomb grid, particles)
- Cookie consent, newsletter signup
- Seasonal guide, testimonials, beginner spotlight

---

## 13. Three.js Splash Animation

First-visit splash on homepage (DE + IT). Skipped on repeat via `sessionStorage`.

```
Timeline (≈4.4s):
 0.0s  Dark scene, golden particles swirl
 0.6s  5 gold bars slide in (alternating sides), assemble hexagon
 1.6s  Honey drop forms with elastic bounce (easeOutBack)
 1.8s  Bee flies in from upper-right, lands on hive
 3.2s  Logo PNG fades over 3D scene
 4.4s  onComplete → splash fades out, reveals page
```

Materials: `MeshStandardMaterial` metalness 0.9, roughness 0.1, emissive gold.
Mini-replay: on scroll-to-top, golden particle burst (1.8s).
Reduced motion: static logo fallback (1.5s display, then fade).

---

## 14. Logo & Branding

**Logo**: 3D gold hexagonal hive (5 bars), realistic bee, honey drop
- Source: `logo/IMG_0866.JPG` (with background), `logo/logo-ohne-back.PNG` (transparent)
- Animation video: `logo/generated_video.MP4`

**App usage** (`assets/images/logo.png`):
- AnimatedLogo widget: fade-in + scale (easeOutBack)
- White container, rounded corners, amber glow shadow
- Used in: onboarding welcome, login, register screens

**Website** (`public/images/beefactory-logo.png`):
- Header logo, hero centrepiece, Three.js splash final frame

---

## 15. Localization

| Scope | DE (German, default) | IT (Italian) |
|-------|---------------------|-------------|
| App UI strings | `l10n/de.dart` | `l10n/it.dart` |
| Voice STT | `de_DE` locale | `it_IT` locale |
| Voice parser | German keywords | Italian keywords |
| Number words | eins…zwanzig | uno…venti |
| Website | `/de/*` routes | `/it/*` routes |
| Website i18n | `lib/i18n.ts` DE map | `lib/i18n.ts` IT map |
| Zone focus texts | German | Italian |

Language stored in SharedPreferences, switchable in Settings via SegmentedButton.

---

## 16. File Structure

```
bee/
├── apps/
│   └── mobile_flutter/          Flutter app
│       ├── lib/
│       │   ├── presentation/    Screens, providers, widgets, router
│       │   ├── domain/          Models, repos, voice, rules
│       │   ├── data/            Local (Drift), remote (HTTP), sync
│       │   ├── core/            Constants, network service
│       │   └── l10n/            DE + IT translations
│       ├── assets/images/       Logo
│       └── pubspec.yaml
├── services/
│   └── api_backend/             NestJS REST API
│       ├── src/
│       │   ├── auth/            JWT auth (register, login, refresh)
│       │   ├── sites/           Sites CRUD
│       │   ├── hives/           Hives CRUD
│       │   ├── events/          Append-only events
│       │   ├── tasks/           Tasks CRUD + DELETE
│       │   ├── community/       Posts, comments, reports
│       │   ├── zones/           Public zone data
│       │   └── attachments/     MinIO presign
│       ├── prisma/              Schema + migrations
│       ├── Dockerfile           Multi-stage Node 20 build
│       └── .env / .env.docker
├── beefactory/                  Astro website
│   ├── src/
│   │   ├── pages/de/, it/       Bilingual pages
│   │   ├── pages/admin/         Admin panel
│   │   ├── components/          Astro + Preact components
│   │   ├── lib/                 three-splash.ts, three-hero.ts, i18n, cart
│   │   └── data/                Products, collections, testimonials
│   └── public/images/           Logo, hero background
├── infra/
│   └── docker-compose.yml       PostgreSQL + MinIO + Backend
├── logo/                        Source logo files + animation video
└── docs/
    └── concept-flow.md          This document
```
