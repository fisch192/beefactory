import { INestApplication } from '@nestjs/common';
import { App } from 'supertest/types';
import request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import {
  createTestApp,
  cleanDatabase,
  registerTestUser,
  TestUser,
} from './setup';

describe('Community (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let user: TestUser;

  beforeAll(async () => {
    ({ app, prisma } = await createTestApp());
    user = await registerTestUser(app, {
      displayName: 'Community Beekeeper',
    });
  });

  afterAll(async () => {
    await cleanDatabase(prisma);
    await app.close();
  });

  // Helper: valid post payload
  function postPayload(overrides?: Record<string, unknown>) {
    return {
      region: 'Suedtirol',
      elevationBand: 'mid',
      title: 'First spring inspection tips?',
      body: 'When is the right time to do the first spring inspection in the mid-elevation Suedtirol region? Looking for advice.',
      tags: ['spring', 'inspection'],
      ...overrides,
    };
  }

  // ──────────────────────────────────────────────────────────────────────
  // POST /v1/community/posts
  // ──────────────────────────────────────────────────────────────────────
  describe('POST /v1/community/posts', () => {
    it('should create a community post', async () => {
      const payload = postPayload();

      const res = await request(app.getHttpServer())
        .post('/v1/community/posts')
        .set('Authorization', `Bearer ${user.accessToken}`)
        .send(payload)
        .expect(201);

      expect(res.body).toHaveProperty('id');
      expect(res.body.title).toBe(payload.title);
      expect(res.body.body).toBe(payload.body);
      expect(res.body.region).toBe('Suedtirol');
      expect(res.body.elevationBand).toBe('mid');
      expect(res.body.tags).toEqual(['spring', 'inspection']);
      expect(res.body.user).toMatchObject({
        id: user.userId,
        displayName: 'Community Beekeeper',
      });
    });

    it('should return 401 without auth', async () => {
      await request(app.getHttpServer())
        .post('/v1/community/posts')
        .send(postPayload())
        .expect(401);
    });

    it('should return 400 with missing required fields', async () => {
      const res = await request(app.getHttpServer())
        .post('/v1/community/posts')
        .set('Authorization', `Bearer ${user.accessToken}`)
        .send({ title: 'Missing region and body' })
        .expect(400);

      expect(res.body.statusCode).toBe(400);
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // GET /v1/community/posts (feed)
  // ──────────────────────────────────────────────────────────────────────
  describe('GET /v1/community/posts', () => {
    beforeAll(async () => {
      // Seed multiple posts across different regions
      const regions = [
        { region: 'Suedtirol', elevationBand: 'mid' },
        { region: 'Suedtirol', elevationBand: 'high' },
        { region: 'Trentino', elevationBand: 'low' },
        { region: 'Suedtirol', elevationBand: 'mid' },
        { region: 'Trentino', elevationBand: 'mid' },
      ];

      for (let i = 0; i < regions.length; i++) {
        await request(app.getHttpServer())
          .post('/v1/community/posts')
          .set('Authorization', `Bearer ${user.accessToken}`)
          .send(
            postPayload({
              ...regions[i],
              title: `Feed test post ${i + 1}`,
              body: `Body of test post ${i + 1} about beekeeping topics.`,
            }),
          )
          .expect(201);
      }
    });

    it('should return posts filtered by region', async () => {
      const res = await request(app.getHttpServer())
        .get('/v1/community/posts?region=Trentino')
        .set('Authorization', `Bearer ${user.accessToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('items');
      expect(res.body.items.length).toBeGreaterThanOrEqual(2);
      for (const post of res.body.items) {
        expect(post.region).toBe('Trentino');
      }
    });

    it('should return posts filtered by region and elevationBand', async () => {
      const res = await request(app.getHttpServer())
        .get('/v1/community/posts?region=Suedtirol&elevationBand=mid')
        .set('Authorization', `Bearer ${user.accessToken}`)
        .expect(200);

      expect(res.body.items.length).toBeGreaterThanOrEqual(2);
      for (const post of res.body.items) {
        expect(post.region).toBe('Suedtirol');
        expect(post.elevationBand).toBe('mid');
      }
    });

    it('should support cursor pagination', async () => {
      const page1 = await request(app.getHttpServer())
        .get('/v1/community/posts?limit=2')
        .set('Authorization', `Bearer ${user.accessToken}`)
        .expect(200);

      expect(page1.body.items.length).toBe(2);
      expect(page1.body.hasMore).toBe(true);
      expect(page1.body.nextCursor).toBeTruthy();

      const page2 = await request(app.getHttpServer())
        .get(`/v1/community/posts?limit=2&cursor=${page1.body.nextCursor}`)
        .set('Authorization', `Bearer ${user.accessToken}`)
        .expect(200);

      expect(page2.body.items.length).toBeGreaterThanOrEqual(1);

      // No overlapping ids
      const ids1 = new Set(page1.body.items.map((p: { id: string }) => p.id));
      for (const post of page2.body.items) {
        expect(ids1.has(post.id)).toBe(false);
      }
    });

    it('should return feed items with comment count', async () => {
      const res = await request(app.getHttpServer())
        .get('/v1/community/posts?limit=1')
        .set('Authorization', `Bearer ${user.accessToken}`)
        .expect(200);

      expect(res.body.items[0]).toHaveProperty('_count');
      expect(res.body.items[0]._count).toHaveProperty('comments');
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // POST /v1/community/comments
  // ──────────────────────────────────────────────────────────────────────
  describe('POST /v1/community/comments', () => {
    let postId: string;

    beforeAll(async () => {
      const res = await request(app.getHttpServer())
        .post('/v1/community/posts')
        .set('Authorization', `Bearer ${user.accessToken}`)
        .send(
          postPayload({
            title: 'Post for comments test',
            body: 'This post will receive comments during e2e testing.',
          }),
        )
        .expect(201);

      postId = res.body.id;
    });

    it('should add a comment to a post', async () => {
      const res = await request(app.getHttpServer())
        .post('/v1/community/comments')
        .set('Authorization', `Bearer ${user.accessToken}`)
        .send({
          postId,
          body: 'Great question! I usually inspect when daytime temps are consistently above 12 degrees Celsius.',
        })
        .expect(201);

      expect(res.body).toHaveProperty('id');
      expect(res.body.postId).toBe(postId);
      expect(res.body.body).toContain('12 degrees');
      expect(res.body.user.id).toBe(user.userId);
    });

    it('should return 404 when commenting on a non-existent post', async () => {
      await request(app.getHttpServer())
        .post('/v1/community/comments')
        .set('Authorization', `Bearer ${user.accessToken}`)
        .send({
          postId: '00000000-0000-0000-0000-000000000000',
          body: 'This should fail',
        })
        .expect(404);
    });

    it('should return the comment in the post detail', async () => {
      const res = await request(app.getHttpServer())
        .get(`/v1/community/posts/${postId}`)
        .set('Authorization', `Bearer ${user.accessToken}`)
        .expect(200);

      expect(res.body.comments.length).toBeGreaterThanOrEqual(1);
      expect(res.body.comments[0].body).toContain('12 degrees');
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // POST /v1/community/reports
  // ──────────────────────────────────────────────────────────────────────
  describe('POST /v1/community/reports', () => {
    let postIdToReport: string;

    beforeAll(async () => {
      const res = await request(app.getHttpServer())
        .post('/v1/community/posts')
        .set('Authorization', `Bearer ${user.accessToken}`)
        .send(
          postPayload({
            title: 'Suspicious post',
            body: 'This post may contain problematic content for testing reports.',
          }),
        )
        .expect(201);

      postIdToReport = res.body.id;
    });

    it('should report a post', async () => {
      const reporter = await registerTestUser(app, {
        displayName: 'Reporter Beekeeper',
      });

      const res = await request(app.getHttpServer())
        .post('/v1/community/reports')
        .set('Authorization', `Bearer ${reporter.accessToken}`)
        .send({
          postId: postIdToReport,
          reason: 'Spam content, not related to beekeeping',
        })
        .expect(201);

      expect(res.body).toHaveProperty('id');
      expect(res.body.postId).toBe(postIdToReport);
      expect(res.body.reason).toContain('Spam');
    });

    it('should return 400 when neither postId nor commentId is provided', async () => {
      const res = await request(app.getHttpServer())
        .post('/v1/community/reports')
        .set('Authorization', `Bearer ${user.accessToken}`)
        .send({ reason: 'Something bad' })
        .expect(400);

      expect(res.body.statusCode).toBe(400);
    });

    it('should return 404 when reporting a non-existent post', async () => {
      await request(app.getHttpServer())
        .post('/v1/community/reports')
        .set('Authorization', `Bearer ${user.accessToken}`)
        .send({
          postId: '00000000-0000-0000-0000-000000000000',
          reason: 'Fake post',
        })
        .expect(404);
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // Rate limiting: max 10 posts per hour
  // ──────────────────────────────────────────────────────────────────────
  describe('Rate limiting', () => {
    it('should reject more than 10 posts in quick succession', async () => {
      // Create a fresh user so the rate limit counter starts at 0
      const rateLimitUser = await registerTestUser(app, {
        displayName: 'Rate Limit Tester',
      });

      // Create 10 posts (should all succeed)
      for (let i = 0; i < 10; i++) {
        await request(app.getHttpServer())
          .post('/v1/community/posts')
          .set('Authorization', `Bearer ${rateLimitUser.accessToken}`)
          .send(
            postPayload({
              title: `Rate limit post ${i + 1}`,
              body: `Rate limit body ${i + 1}`,
            }),
          )
          .expect(201);
      }

      // The 11th should be rejected
      const res = await request(app.getHttpServer())
        .post('/v1/community/posts')
        .set('Authorization', `Bearer ${rateLimitUser.accessToken}`)
        .send(
          postPayload({
            title: 'Rate limit post 11',
            body: 'This one should fail',
          }),
        )
        .expect(403);

      expect(res.body.statusCode).toBe(403);
      expect(res.body.message).toMatch(/rate limit/i);
    });
  });
});
