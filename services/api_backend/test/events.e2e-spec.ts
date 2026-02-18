import { INestApplication } from '@nestjs/common';
import { App } from 'supertest/types';
import request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import {
  createTestApp,
  cleanDatabase,
  registerTestUser,
  createTestSite,
  createTestHive,
  TestUser,
} from './setup';

describe('Events (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let user: TestUser;
  let siteId: string;
  let hiveId: string;

  beforeAll(async () => {
    ({ app, prisma } = await createTestApp());
    user = await registerTestUser(app);

    const site = await createTestSite(app, user.accessToken, {
      name: 'Apiary Vinschgau',
      location: 'Vinschgau valley, Suedtirol',
    });
    siteId = site['id'] as string;

    const hive = await createTestHive(app, user.accessToken, siteId, {
      number: 1,
      name: 'Carnica Queen 2024',
    });
    hiveId = hive['id'] as string;
  });

  afterAll(async () => {
    await cleanDatabase(prisma);
    await app.close();
  });

  // Helper: build a valid event payload
  function eventPayload(overrides?: Record<string, unknown>) {
    return {
      clientEventId: `evt-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
      siteId,
      hiveId,
      type: 'INSPECTION',
      occurredAtLocal: '2025-06-15T10:30:00',
      occurredAtUtc: '2025-06-15T08:30:00.000Z',
      payload: { broodFrames: 6, honeyFrames: 3, temperament: 'calm' },
      source: 'MANUAL',
      ...overrides,
    };
  }

  // ──────────────────────────────────────────────────────────────────────
  // POST /v1/events
  // ──────────────────────────────────────────────────────────────────────
  describe('POST /v1/events', () => {
    it('should create an event successfully', async () => {
      const payload = eventPayload();

      const res = await request(app.getHttpServer())
        .post('/v1/events')
        .set('Authorization', `Bearer ${user.accessToken}`)
        .send(payload)
        .expect(201);

      expect(res.body).toHaveProperty('id');
      expect(res.body.clientEventId).toBe(payload.clientEventId);
      expect(res.body.type).toBe('INSPECTION');
      expect(res.body.siteId).toBe(siteId);
      expect(res.body.hiveId).toBe(hiveId);
      expect(res.body.payload).toMatchObject({ broodFrames: 6 });
    });

    it('should be idempotent: same clientEventId returns the same event', async () => {
      const payload = eventPayload();

      const first = await request(app.getHttpServer())
        .post('/v1/events')
        .set('Authorization', `Bearer ${user.accessToken}`)
        .send(payload)
        .expect(201);

      const second = await request(app.getHttpServer())
        .post('/v1/events')
        .set('Authorization', `Bearer ${user.accessToken}`)
        .send(payload)
        .expect(201);

      expect(first.body.id).toBe(second.body.id);
    });

    it('should return 401 without auth', async () => {
      const res = await request(app.getHttpServer())
        .post('/v1/events')
        .send(eventPayload())
        .expect(401);

      expect(res.body.statusCode).toBe(401);
    });

    it('should return 400 with invalid event type', async () => {
      const res = await request(app.getHttpServer())
        .post('/v1/events')
        .set('Authorization', `Bearer ${user.accessToken}`)
        .send(eventPayload({ type: 'COMPLETELY_INVALID_TYPE' }))
        .expect(400);

      expect(res.body.statusCode).toBe(400);
    });

    it('should create a site-level event without hiveId', async () => {
      const payload = eventPayload({ hiveId: undefined, type: 'NOTE' });
      delete (payload as Record<string, unknown>)['hiveId'];

      const res = await request(app.getHttpServer())
        .post('/v1/events')
        .set('Authorization', `Bearer ${user.accessToken}`)
        .send(payload)
        .expect(201);

      expect(res.body.hiveId).toBeNull();
      expect(res.body.type).toBe('NOTE');
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // GET /v1/events
  // ──────────────────────────────────────────────────────────────────────
  describe('GET /v1/events', () => {
    let secondSiteId: string;
    let secondHiveId: string;

    beforeAll(async () => {
      // Create a second site + hive so we can test filtering
      const site2 = await createTestSite(app, user.accessToken, {
        name: 'Talstand Bozen',
        location: 'Bozen, Suedtirol',
        latitude: 46.4983,
        longitude: 11.3548,
        elevation: 260,
      });
      secondSiteId = site2['id'] as string;

      const hive2 = await createTestHive(app, user.accessToken, secondSiteId, {
        number: 1,
        name: 'Italian Bee Colony',
      });
      secondHiveId = hive2['id'] as string;

      // Seed some events across both sites
      const events = [
        eventPayload({ type: 'INSPECTION' }),
        eventPayload({ type: 'FEEDING', payload: { feedType: 'sugar syrup', amountKg: 2 } }),
        eventPayload({ type: 'HARVEST', payload: { honeyKg: 12 } }),
        eventPayload({ siteId: secondSiteId, hiveId: secondHiveId, type: 'VARROA_MEASUREMENT', payload: { miteCount: 3 } }),
        eventPayload({ siteId: secondSiteId, hiveId: secondHiveId, type: 'TREATMENT', payload: { product: 'Oxalic acid' } }),
      ];

      for (const evt of events) {
        await request(app.getHttpServer())
          .post('/v1/events')
          .set('Authorization', `Bearer ${user.accessToken}`)
          .send(evt)
          .expect(201);
      }
    });

    it('should return the user\'s events', async () => {
      const res = await request(app.getHttpServer())
        .get('/v1/events')
        .set('Authorization', `Bearer ${user.accessToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('items');
      expect(res.body).toHaveProperty('hasMore');
      expect(Array.isArray(res.body.items)).toBe(true);
      expect(res.body.items.length).toBeGreaterThanOrEqual(5);
    });

    it('should filter events by siteId', async () => {
      const res = await request(app.getHttpServer())
        .get(`/v1/events?siteId=${secondSiteId}`)
        .set('Authorization', `Bearer ${user.accessToken}`)
        .expect(200);

      expect(res.body.items.length).toBeGreaterThanOrEqual(2);
      for (const item of res.body.items) {
        expect(item.siteId).toBe(secondSiteId);
      }
    });

    it('should filter events by hiveId', async () => {
      const res = await request(app.getHttpServer())
        .get(`/v1/events?hiveId=${secondHiveId}`)
        .set('Authorization', `Bearer ${user.accessToken}`)
        .expect(200);

      expect(res.body.items.length).toBeGreaterThanOrEqual(2);
      for (const item of res.body.items) {
        expect(item.hiveId).toBe(secondHiveId);
      }
    });

    it('should filter events by "since" timestamp', async () => {
      // All our test events are brand new, so "since 1 hour ago" should include them
      const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString();

      const res = await request(app.getHttpServer())
        .get(`/v1/events?since=${oneHourAgo}`)
        .set('Authorization', `Bearer ${user.accessToken}`)
        .expect(200);

      expect(res.body.items.length).toBeGreaterThanOrEqual(5);

      // "since far in the future" should return nothing
      const future = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString();
      const emptyRes = await request(app.getHttpServer())
        .get(`/v1/events?since=${future}`)
        .set('Authorization', `Bearer ${user.accessToken}`)
        .expect(200);

      expect(emptyRes.body.items.length).toBe(0);
    });

    it('should paginate with limit and cursor', async () => {
      // Page 1: fetch 2 items
      const page1 = await request(app.getHttpServer())
        .get('/v1/events?limit=2')
        .set('Authorization', `Bearer ${user.accessToken}`)
        .expect(200);

      expect(page1.body.items.length).toBe(2);
      expect(page1.body.hasMore).toBe(true);
      expect(page1.body.nextCursor).toBeTruthy();

      // Page 2: use cursor
      const page2 = await request(app.getHttpServer())
        .get(`/v1/events?limit=2&cursor=${page1.body.nextCursor}`)
        .set('Authorization', `Bearer ${user.accessToken}`)
        .expect(200);

      expect(page2.body.items.length).toBeGreaterThanOrEqual(1);

      // Page 1 and page 2 should not share ids
      const page1Ids = page1.body.items.map((e: { id: string }) => e.id);
      const page2Ids = page2.body.items.map((e: { id: string }) => e.id);
      const overlap = page1Ids.filter((id: string) => page2Ids.includes(id));
      expect(overlap.length).toBe(0);
    });

    it('should not return events from another user', async () => {
      const otherUser = await registerTestUser(app, {
        displayName: 'Other Beekeeper',
      });

      const res = await request(app.getHttpServer())
        .get('/v1/events')
        .set('Authorization', `Bearer ${otherUser.accessToken}`)
        .expect(200);

      // Other user has no events
      expect(res.body.items.length).toBe(0);
    });
  });
});
