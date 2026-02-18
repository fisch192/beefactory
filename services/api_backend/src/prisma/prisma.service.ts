import { Injectable, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  constructor() {
    const url = new URL(
      process.env['DATABASE_URL'] ?? 'postgresql://bee:bee_dev_pass@localhost:5432/bee',
    );
    const pool = new pg.Pool({
      host: url.hostname,
      port: Number(url.port) || 5432,
      user: url.username,
      password: url.password,
      database: url.pathname.replace('/', ''),
    });
    const adapter = new PrismaPg(pool);
    super({ adapter });
  }

  async onModuleInit(): Promise<void> {
    await this.$connect();
  }
}
