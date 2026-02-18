import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import request from 'supertest';
import { App } from 'supertest/types';
import { PrismaService } from '../src/prisma/prisma.service';
import { PrismaModule } from '../src/prisma/prisma.module';
import { AuthModule } from '../src/auth/auth.module';
import { SitesModule } from '../src/sites/sites.module';
import { HivesModule } from '../src/hives/hives.module';
import { EventsModule } from '../src/events/events.module';
import { CommunityModule } from '../src/community/community.module';
import { GlobalExceptionFilter } from '../src/common/filters/http-exception.filter';

// ─── Constants ──────────────────────────────────────────────────────────
export const JWT_SECRET = 'e2e-test-secret';
export const JWT_REFRESH_SECRET = 'e2e-test-refresh-secret';

// ─── App bootstrap ──────────────────────────────────────────────────────
export async function createTestApp(): Promise<{
  app: INestApplication<App>;
  prisma: PrismaService;
  jwtService: JwtService;
}> {
  // Ensure deterministic secrets for the test run
  process.env['JWT_SECRET'] = JWT_SECRET;
  process.env['JWT_REFRESH_SECRET'] = JWT_REFRESH_SECRET;

  const moduleFixture: TestingModule = await Test.createTestingModule({
    imports: [
      PrismaModule,
      AuthModule,
      SitesModule,
      HivesModule,
      EventsModule,
      CommunityModule,
    ],
  }).compile();

  const app = moduleFixture.createNestApplication();

  // Replicate the same pipes / filters the real app would use
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  app.useGlobalFilters(new GlobalExceptionFilter());

  await app.init();

  const prisma = moduleFixture.get<PrismaService>(PrismaService);
  const jwtService = moduleFixture.get<JwtService>(JwtService);

  return { app, prisma, jwtService };
}

// ─── Unique email generator (avoids collisions between parallel runs) ───
let emailCounter = 0;
export function uniqueEmail(prefix = 'beekeeper'): string {
  emailCounter += 1;
  return `${prefix}+${Date.now()}-${emailCounter}@e2etest.bee`;
}

// ─── Register a user via the HTTP API and return tokens + user info ─────
export interface TestUser {
  accessToken: string;
  refreshToken: string;
  userId: string;
  email: string;
}

export async function registerTestUser(
  app: INestApplication<App>,
  overrides?: { email?: string; password?: string; displayName?: string },
): Promise<TestUser> {
  const email = overrides?.email ?? uniqueEmail();
  const password = overrides?.password ?? 'TestPass123!';
  const displayName = overrides?.displayName ?? 'E2E Beekeeper';

  const res = await request(app.getHttpServer())
    .post('/v1/auth/register')
    .send({ email, password, displayName })
    .expect(201);

  return {
    accessToken: res.body.accessToken,
    refreshToken: res.body.refreshToken,
    userId: res.body.user.id,
    email,
  };
}

// ─── Create a site for a given test user ────────────────────────────────
export async function createTestSite(
  app: INestApplication<App>,
  token: string,
  overrides?: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  const payload = {
    name: 'Bergstand Meran',
    location: 'Meran, Suedtirol',
    latitude: 46.6713,
    longitude: 11.1535,
    elevation: 600,
    notes: 'South-facing hillside, sheltered from north wind',
    ...overrides,
  };

  const res = await request(app.getHttpServer())
    .post('/v1/sites')
    .set('Authorization', `Bearer ${token}`)
    .send(payload)
    .expect(201);

  return res.body;
}

// ─── Create a hive for a given site ─────────────────────────────────────
export async function createTestHive(
  app: INestApplication<App>,
  token: string,
  siteId: string,
  overrides?: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  const payload = {
    siteId,
    number: 1,
    name: 'Buckfast Colony',
    queenYear: 2024,
    queenColor: 'green',
    queenMarked: true,
    notes: 'Gentle temperament, good honey producer',
    ...overrides,
  };

  const res = await request(app.getHttpServer())
    .post('/v1/hives')
    .set('Authorization', `Bearer ${token}`)
    .send(payload)
    .expect(201);

  return res.body;
}

// ─── Database cleanup ───────────────────────────────────────────────────
// Deletes all rows from every table used by the tests, in FK-safe order.
export async function cleanDatabase(prisma: PrismaService): Promise<void> {
  // Order matters: children before parents
  await prisma.report.deleteMany();
  await prisma.communityComment.deleteMany();
  await prisma.communityPost.deleteMany();
  await prisma.event.deleteMany();
  await prisma.task.deleteMany();
  await prisma.hive.deleteMany();
  await prisma.site.deleteMany();
  await prisma.user.deleteMany();
}
