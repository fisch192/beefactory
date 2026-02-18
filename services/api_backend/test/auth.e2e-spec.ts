import { INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { App } from 'supertest/types';
import request from 'supertest';
import { PrismaService } from '../src/prisma/prisma.service';
import {
  createTestApp,
  cleanDatabase,
  uniqueEmail,
  registerTestUser,
  JWT_REFRESH_SECRET,
} from './setup';

describe('Auth (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let jwtService: JwtService;

  beforeAll(async () => {
    ({ app, prisma, jwtService } = await createTestApp());
  });

  afterAll(async () => {
    await cleanDatabase(prisma);
    await app.close();
  });

  // ──────────────────────────────────────────────────────────────────────
  // POST /v1/auth/register
  // ──────────────────────────────────────────────────────────────────────
  describe('POST /v1/auth/register', () => {
    it('should register a new user and return tokens', async () => {
      const email = uniqueEmail('register-ok');
      const res = await request(app.getHttpServer())
        .post('/v1/auth/register')
        .send({
          email,
          password: 'HoneyBee2024!',
          displayName: 'Anna Imkerin',
        })
        .expect(201);

      expect(res.body).toHaveProperty('accessToken');
      expect(res.body).toHaveProperty('refreshToken');
      expect(res.body.user).toMatchObject({
        email,
        displayName: 'Anna Imkerin',
        role: 'USER',
      });
      expect(res.body.user).toHaveProperty('id');
    });

    it('should return 409 when email is already registered', async () => {
      const email = uniqueEmail('dup');
      // First registration
      await request(app.getHttpServer())
        .post('/v1/auth/register')
        .send({ email, password: 'HoneyBee2024!', displayName: 'First' })
        .expect(201);

      // Duplicate
      const res = await request(app.getHttpServer())
        .post('/v1/auth/register')
        .send({ email, password: 'HoneyBee2024!', displayName: 'Second' })
        .expect(409);

      expect(res.body.statusCode).toBe(409);
      expect(res.body.message).toMatch(/already registered/i);
    });

    it('should return 400 when password is shorter than 8 characters', async () => {
      const res = await request(app.getHttpServer())
        .post('/v1/auth/register')
        .send({
          email: uniqueEmail('short-pw'),
          password: 'abc',
          displayName: 'Short PW',
        })
        .expect(400);

      expect(res.body.statusCode).toBe(400);
      // class-validator returns an array of messages
      const messages = Array.isArray(res.body.message)
        ? res.body.message
        : [res.body.message];
      const hasMinLength = messages.some((m: string) =>
        /must be longer than or equal to 8/i.test(m),
      );
      expect(hasMinLength).toBe(true);
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // POST /v1/auth/login
  // ──────────────────────────────────────────────────────────────────────
  describe('POST /v1/auth/login', () => {
    const loginEmail = uniqueEmail('login');
    const loginPassword = 'BeekeeperPass1!';

    beforeAll(async () => {
      await request(app.getHttpServer())
        .post('/v1/auth/register')
        .send({ email: loginEmail, password: loginPassword, displayName: 'Login User' })
        .expect(201);
    });

    it('should return access and refresh tokens on valid credentials', async () => {
      const res = await request(app.getHttpServer())
        .post('/v1/auth/login')
        .send({ email: loginEmail, password: loginPassword })
        .expect(200);

      expect(res.body).toHaveProperty('accessToken');
      expect(res.body).toHaveProperty('refreshToken');
      expect(res.body.user.email).toBe(loginEmail);
      expect(typeof res.body.accessToken).toBe('string');
      expect(typeof res.body.refreshToken).toBe('string');
    });

    it('should return 401 with wrong password', async () => {
      const res = await request(app.getHttpServer())
        .post('/v1/auth/login')
        .send({ email: loginEmail, password: 'WrongPassword99!' })
        .expect(401);

      expect(res.body.statusCode).toBe(401);
      expect(res.body.message).toMatch(/invalid credentials/i);
    });

    it('should return 401 with non-existent email', async () => {
      const res = await request(app.getHttpServer())
        .post('/v1/auth/login')
        .send({ email: 'nobody@nowhere.dev', password: 'Whatever123!' })
        .expect(401);

      expect(res.body.statusCode).toBe(401);
    });
  });

  // ──────────────────────────────────────────────────────────────────────
  // POST /v1/auth/refresh
  // ──────────────────────────────────────────────────────────────────────
  describe('POST /v1/auth/refresh', () => {
    it('should return new tokens when a valid refresh token is provided', async () => {
      const user = await registerTestUser(app);

      const res = await request(app.getHttpServer())
        .post('/v1/auth/refresh')
        .send({ refreshToken: user.refreshToken })
        .expect(200);

      expect(res.body).toHaveProperty('accessToken');
      expect(res.body).toHaveProperty('refreshToken');
      expect(typeof res.body.accessToken).toBe('string');
      // New tokens should be different strings from the originals
      // (they can theoretically be the same only if issued within the same second,
      //  but practically they differ because of iat)
    });

    it('should return 401 with an invalid / malformed refresh token', async () => {
      const res = await request(app.getHttpServer())
        .post('/v1/auth/refresh')
        .send({ refreshToken: 'this.is.not.a.valid.jwt' })
        .expect(401);

      expect(res.body.statusCode).toBe(401);
      expect(res.body.message).toMatch(/invalid refresh token/i);
    });

    it('should return 401 with an expired refresh token', async () => {
      // Manually craft a token that expired one hour ago
      const expiredToken = jwtService.sign(
        { sub: '00000000-0000-0000-0000-000000000000', email: 'expired@test.bee' },
        { secret: JWT_REFRESH_SECRET, expiresIn: '-1h' },
      );

      const res = await request(app.getHttpServer())
        .post('/v1/auth/refresh')
        .send({ refreshToken: expiredToken })
        .expect(401);

      expect(res.body.statusCode).toBe(401);
    });

    it('should return 401 when the refresh token references a deleted user', async () => {
      const user = await registerTestUser(app);

      // Soft-delete the user directly in the DB
      await prisma.user.update({
        where: { id: user.userId },
        data: { deletedAt: new Date() },
      });

      const res = await request(app.getHttpServer())
        .post('/v1/auth/refresh')
        .send({ refreshToken: user.refreshToken })
        .expect(401);

      expect(res.body.statusCode).toBe(401);
    });
  });
});
