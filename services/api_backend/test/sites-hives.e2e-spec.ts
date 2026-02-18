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

describe('Sites & Hives (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let user: TestUser;

  beforeAll(async () => {
    ({ app, prisma } = await createTestApp());
    user = await registerTestUser(app, {
      displayName: 'Apiarist Max',
    });
  });

  afterAll(async () => {
    await cleanDatabase(prisma);
    await app.close();
  });

  // ====================================================================
  //  SITES
  // ====================================================================
  describe('Sites CRUD', () => {
    let siteId: string;

    // ── Create ──────────────────────────────────────────────────────────
    describe('POST /v1/sites', () => {
      it('should create a site', async () => {
        const res = await request(app.getHttpServer())
          .post('/v1/sites')
          .set('Authorization', `Bearer ${user.accessToken}`)
          .send({
            name: 'Bergstand Meran',
            location: 'Meran, Suedtirol',
            latitude: 46.6713,
            longitude: 11.1535,
            elevation: 600,
            notes: 'South-facing slope, sheltered from wind',
          })
          .expect(201);

        siteId = res.body.id;

        expect(res.body.name).toBe('Bergstand Meran');
        expect(res.body.latitude).toBeCloseTo(46.6713);
        expect(res.body.longitude).toBeCloseTo(11.1535);
        expect(res.body.elevation).toBe(600);
        expect(res.body.userId).toBe(user.userId);
      });

      it('should create a site with minimal data', async () => {
        const res = await request(app.getHttpServer())
          .post('/v1/sites')
          .set('Authorization', `Bearer ${user.accessToken}`)
          .send({ name: 'Waldrand Lana' })
          .expect(201);

        expect(res.body.name).toBe('Waldrand Lana');
        expect(res.body.location).toBeNull();
      });

      it('should return 401 without auth', async () => {
        await request(app.getHttpServer())
          .post('/v1/sites')
          .send({ name: 'No Auth Site' })
          .expect(401);
      });

      it('should return 400 with missing name', async () => {
        await request(app.getHttpServer())
          .post('/v1/sites')
          .set('Authorization', `Bearer ${user.accessToken}`)
          .send({ location: 'Somewhere' })
          .expect(400);
      });
    });

    // ── Read All ────────────────────────────────────────────────────────
    describe('GET /v1/sites', () => {
      it('should list all sites for the user', async () => {
        const res = await request(app.getHttpServer())
          .get('/v1/sites')
          .set('Authorization', `Bearer ${user.accessToken}`)
          .expect(200);

        expect(Array.isArray(res.body)).toBe(true);
        expect(res.body.length).toBeGreaterThanOrEqual(2);
        // Should include hive count
        expect(res.body[0]).toHaveProperty('_count');
      });
    });

    // ── Read One ────────────────────────────────────────────────────────
    describe('GET /v1/sites/:id', () => {
      it('should return a single site with hives', async () => {
        const res = await request(app.getHttpServer())
          .get(`/v1/sites/${siteId}`)
          .set('Authorization', `Bearer ${user.accessToken}`)
          .expect(200);

        expect(res.body.id).toBe(siteId);
        expect(res.body.name).toBe('Bergstand Meran');
        expect(res.body).toHaveProperty('hives');
        expect(Array.isArray(res.body.hives)).toBe(true);
      });

      it('should return 404 for non-existent site', async () => {
        await request(app.getHttpServer())
          .get('/v1/sites/00000000-0000-0000-0000-000000000000')
          .set('Authorization', `Bearer ${user.accessToken}`)
          .expect(404);
      });
    });

    // ── Update ──────────────────────────────────────────────────────────
    describe('PUT /v1/sites/:id', () => {
      it('should update site fields', async () => {
        const res = await request(app.getHttpServer())
          .put(`/v1/sites/${siteId}`)
          .set('Authorization', `Bearer ${user.accessToken}`)
          .send({
            name: 'Bergstand Meran (updated)',
            elevation: 620,
            notes: 'Moved hives 20 meters uphill',
          })
          .expect(200);

        expect(res.body.name).toBe('Bergstand Meran (updated)');
        expect(res.body.elevation).toBe(620);
        expect(res.body.notes).toBe('Moved hives 20 meters uphill');
        // Fields not sent should remain unchanged
        expect(res.body.latitude).toBeCloseTo(46.6713);
      });

      it('should return 404 when updating non-existent site', async () => {
        await request(app.getHttpServer())
          .put('/v1/sites/00000000-0000-0000-0000-000000000000')
          .set('Authorization', `Bearer ${user.accessToken}`)
          .send({ name: 'Ghost' })
          .expect(404);
      });
    });

    // ── Soft Delete ─────────────────────────────────────────────────────
    describe('DELETE /v1/sites/:id', () => {
      let deletableSiteId: string;

      beforeAll(async () => {
        const site = await createTestSite(app, user.accessToken, {
          name: 'Soon To Be Deleted',
        });
        deletableSiteId = site['id'] as string;
      });

      it('should soft-delete a site', async () => {
        const res = await request(app.getHttpServer())
          .delete(`/v1/sites/${deletableSiteId}`)
          .set('Authorization', `Bearer ${user.accessToken}`)
          .expect(200);

        expect(res.body.deletedAt).toBeTruthy();
      });

      it('should not return the soft-deleted site in list', async () => {
        const res = await request(app.getHttpServer())
          .get('/v1/sites')
          .set('Authorization', `Bearer ${user.accessToken}`)
          .expect(200);

        const ids = res.body.map((s: { id: string }) => s.id);
        expect(ids).not.toContain(deletableSiteId);
      });

      it('should return 404 when fetching a soft-deleted site', async () => {
        await request(app.getHttpServer())
          .get(`/v1/sites/${deletableSiteId}`)
          .set('Authorization', `Bearer ${user.accessToken}`)
          .expect(404);
      });
    });

    // ── Cross-user isolation ────────────────────────────────────────────
    describe('Cross-user isolation', () => {
      it('should not allow access to another user\'s site', async () => {
        const otherUser = await registerTestUser(app, {
          displayName: 'Other Apiarist',
        });

        // Other user tries to read our site
        await request(app.getHttpServer())
          .get(`/v1/sites/${siteId}`)
          .set('Authorization', `Bearer ${otherUser.accessToken}`)
          .expect(404);

        // Other user tries to update our site
        await request(app.getHttpServer())
          .put(`/v1/sites/${siteId}`)
          .set('Authorization', `Bearer ${otherUser.accessToken}`)
          .send({ name: 'Hijacked' })
          .expect(404);

        // Other user tries to delete our site
        await request(app.getHttpServer())
          .delete(`/v1/sites/${siteId}`)
          .set('Authorization', `Bearer ${otherUser.accessToken}`)
          .expect(404);
      });

      it('other user should see an empty site list', async () => {
        const freshUser = await registerTestUser(app, {
          displayName: 'Empty Beekeeper',
        });

        const res = await request(app.getHttpServer())
          .get('/v1/sites')
          .set('Authorization', `Bearer ${freshUser.accessToken}`)
          .expect(200);

        expect(res.body.length).toBe(0);
      });
    });
  });

  // ====================================================================
  //  HIVES
  // ====================================================================
  describe('Hives CRUD', () => {
    let hiveSiteId: string;
    let hiveId: string;

    beforeAll(async () => {
      const site = await createTestSite(app, user.accessToken, {
        name: 'Hive Test Apiary',
        location: 'Ritten, Suedtirol',
        elevation: 900,
      });
      hiveSiteId = site['id'] as string;
    });

    // ── Create ──────────────────────────────────────────────────────────
    describe('POST /v1/hives', () => {
      it('should create a hive in a site', async () => {
        const res = await request(app.getHttpServer())
          .post('/v1/hives')
          .set('Authorization', `Bearer ${user.accessToken}`)
          .send({
            siteId: hiveSiteId,
            number: 1,
            name: 'Buckfast Colony A',
            queenYear: 2024,
            queenColor: 'green',
            queenMarked: true,
            notes: 'Strong colony, gentle temperament',
          })
          .expect(201);

        hiveId = res.body.id;

        expect(res.body.siteId).toBe(hiveSiteId);
        expect(res.body.number).toBe(1);
        expect(res.body.name).toBe('Buckfast Colony A');
        expect(res.body.queenYear).toBe(2024);
        expect(res.body.queenColor).toBe('green');
        expect(res.body.queenMarked).toBe(true);
      });

      it('should create a second hive in the same site', async () => {
        const res = await request(app.getHttpServer())
          .post('/v1/hives')
          .set('Authorization', `Bearer ${user.accessToken}`)
          .send({
            siteId: hiveSiteId,
            number: 2,
            name: 'Carnica Colony B',
            queenYear: 2023,
            queenColor: 'red',
            queenMarked: false,
          })
          .expect(201);

        expect(res.body.number).toBe(2);
        expect(res.body.siteId).toBe(hiveSiteId);
      });

      it('should return 404 when siteId does not belong to user', async () => {
        const otherUser = await registerTestUser(app, {
          displayName: 'Hive Thief',
        });

        await request(app.getHttpServer())
          .post('/v1/hives')
          .set('Authorization', `Bearer ${otherUser.accessToken}`)
          .send({
            siteId: hiveSiteId,
            number: 99,
            name: 'Stolen Hive',
          })
          .expect(404);
      });

      it('should return 400 with missing required fields', async () => {
        await request(app.getHttpServer())
          .post('/v1/hives')
          .set('Authorization', `Bearer ${user.accessToken}`)
          .send({ name: 'No siteId or number' })
          .expect(400);
      });

      it('should return 401 without auth', async () => {
        await request(app.getHttpServer())
          .post('/v1/hives')
          .send({ siteId: hiveSiteId, number: 1 })
          .expect(401);
      });
    });

    // ── Read All ────────────────────────────────────────────────────────
    describe('GET /v1/hives', () => {
      it('should list all hives for the user', async () => {
        const res = await request(app.getHttpServer())
          .get('/v1/hives')
          .set('Authorization', `Bearer ${user.accessToken}`)
          .expect(200);

        expect(Array.isArray(res.body)).toBe(true);
        expect(res.body.length).toBeGreaterThanOrEqual(2);
        // Each hive should include its site info
        expect(res.body[0]).toHaveProperty('site');
        expect(res.body[0].site).toHaveProperty('name');
      });

      it('should filter hives by siteId', async () => {
        const res = await request(app.getHttpServer())
          .get(`/v1/hives?siteId=${hiveSiteId}`)
          .set('Authorization', `Bearer ${user.accessToken}`)
          .expect(200);

        expect(res.body.length).toBeGreaterThanOrEqual(2);
        for (const hive of res.body) {
          expect(hive.siteId).toBe(hiveSiteId);
        }
      });
    });

    // ── Read One ────────────────────────────────────────────────────────
    describe('GET /v1/hives/:id', () => {
      it('should return a single hive', async () => {
        const res = await request(app.getHttpServer())
          .get(`/v1/hives/${hiveId}`)
          .set('Authorization', `Bearer ${user.accessToken}`)
          .expect(200);

        expect(res.body.id).toBe(hiveId);
        expect(res.body.name).toBe('Buckfast Colony A');
        expect(res.body.site).toHaveProperty('id', hiveSiteId);
      });

      it('should return 404 for non-existent hive', async () => {
        await request(app.getHttpServer())
          .get('/v1/hives/00000000-0000-0000-0000-000000000000')
          .set('Authorization', `Bearer ${user.accessToken}`)
          .expect(404);
      });
    });

    // ── Update ──────────────────────────────────────────────────────────
    describe('PUT /v1/hives/:id', () => {
      it('should update hive fields', async () => {
        const res = await request(app.getHttpServer())
          .put(`/v1/hives/${hiveId}`)
          .set('Authorization', `Bearer ${user.accessToken}`)
          .send({
            name: 'Buckfast Colony A (requeened)',
            queenYear: 2025,
            queenColor: 'blue',
            queenMarked: true,
            notes: 'Requeened in autumn 2025',
          })
          .expect(200);

        expect(res.body.name).toBe('Buckfast Colony A (requeened)');
        expect(res.body.queenYear).toBe(2025);
        expect(res.body.queenColor).toBe('blue');
        // number should remain 1
        expect(res.body.number).toBe(1);
      });

      it('should return 404 when updating non-existent hive', async () => {
        await request(app.getHttpServer())
          .put('/v1/hives/00000000-0000-0000-0000-000000000000')
          .set('Authorization', `Bearer ${user.accessToken}`)
          .send({ name: 'Ghost Hive' })
          .expect(404);
      });
    });

    // ── Soft Delete ─────────────────────────────────────────────────────
    describe('DELETE /v1/hives/:id', () => {
      let deletableHiveId: string;

      beforeAll(async () => {
        const hive = await createTestHive(app, user.accessToken, hiveSiteId, {
          number: 99,
          name: 'Colony to Delete',
        });
        deletableHiveId = hive['id'] as string;
      });

      it('should soft-delete a hive', async () => {
        const res = await request(app.getHttpServer())
          .delete(`/v1/hives/${deletableHiveId}`)
          .set('Authorization', `Bearer ${user.accessToken}`)
          .expect(200);

        expect(res.body.deletedAt).toBeTruthy();
      });

      it('should not return the soft-deleted hive in list', async () => {
        const res = await request(app.getHttpServer())
          .get(`/v1/hives?siteId=${hiveSiteId}`)
          .set('Authorization', `Bearer ${user.accessToken}`)
          .expect(200);

        const ids = res.body.map((h: { id: string }) => h.id);
        expect(ids).not.toContain(deletableHiveId);
      });

      it('should return 404 when fetching a soft-deleted hive', async () => {
        await request(app.getHttpServer())
          .get(`/v1/hives/${deletableHiveId}`)
          .set('Authorization', `Bearer ${user.accessToken}`)
          .expect(404);
      });

      it('should exclude soft-deleted hives from site detail', async () => {
        const res = await request(app.getHttpServer())
          .get(`/v1/sites/${hiveSiteId}`)
          .set('Authorization', `Bearer ${user.accessToken}`)
          .expect(200);

        const hiveIds = res.body.hives.map((h: { id: string }) => h.id);
        expect(hiveIds).not.toContain(deletableHiveId);
      });
    });

    // ── Cross-user isolation for hives ──────────────────────────────────
    describe('Cross-user hive isolation', () => {
      it('should not allow another user to access hives', async () => {
        const otherUser = await registerTestUser(app, {
          displayName: 'Hive Spy',
        });

        // Read
        await request(app.getHttpServer())
          .get(`/v1/hives/${hiveId}`)
          .set('Authorization', `Bearer ${otherUser.accessToken}`)
          .expect(404);

        // Update
        await request(app.getHttpServer())
          .put(`/v1/hives/${hiveId}`)
          .set('Authorization', `Bearer ${otherUser.accessToken}`)
          .send({ name: 'Hijacked' })
          .expect(404);

        // Delete
        await request(app.getHttpServer())
          .delete(`/v1/hives/${hiveId}`)
          .set('Authorization', `Bearer ${otherUser.accessToken}`)
          .expect(404);
      });
    });

    // ── Hives scoped to site ────────────────────────────────────────────
    describe('Hives scoped to site', () => {
      it('should only return hives belonging to the requested site', async () => {
        // Create a second site with its own hive
        const site2 = await createTestSite(app, user.accessToken, {
          name: 'Second Apiary',
          location: 'Kaltern, Suedtirol',
        });
        const site2Id = site2['id'] as string;

        await createTestHive(app, user.accessToken, site2Id, {
          number: 1,
          name: 'Wine Country Bees',
        });

        // Fetch hives scoped to original site
        const res = await request(app.getHttpServer())
          .get(`/v1/hives?siteId=${hiveSiteId}`)
          .set('Authorization', `Bearer ${user.accessToken}`)
          .expect(200);

        for (const hive of res.body) {
          expect(hive.siteId).toBe(hiveSiteId);
        }

        // Fetch hives scoped to site 2
        const res2 = await request(app.getHttpServer())
          .get(`/v1/hives?siteId=${site2Id}`)
          .set('Authorization', `Bearer ${user.accessToken}`)
          .expect(200);

        expect(res2.body.length).toBeGreaterThanOrEqual(1);
        for (const hive of res2.body) {
          expect(hive.siteId).toBe(site2Id);
        }
      });
    });
  });
});
