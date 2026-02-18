import { Module, ValidationPipe } from '@nestjs/common';
import { APP_PIPE, APP_FILTER } from '@nestjs/core';
import { ThrottlerModule } from '@nestjs/throttler';
import { PrismaModule } from './prisma/prisma.module.js';
import { AuthModule } from './auth/auth.module.js';
import { SitesModule } from './sites/sites.module.js';
import { HivesModule } from './hives/hives.module.js';
import { EventsModule } from './events/events.module.js';
import { TasksModule } from './tasks/tasks.module.js';
import { CommunityModule } from './community/community.module.js';
import { ZonesModule } from './zones/zones.module.js';
import { AttachmentsModule } from './attachments/attachments.module.js';
import { GlobalExceptionFilter } from './common/filters/http-exception.filter.js';

@Module({
  imports: [
    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 60,
      },
    ]),
    PrismaModule,
    AuthModule,
    SitesModule,
    HivesModule,
    EventsModule,
    TasksModule,
    CommunityModule,
    ZonesModule,
    AttachmentsModule,
  ],
  providers: [
    {
      provide: APP_PIPE,
      useValue: new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
        transformOptions: { enableImplicitConversion: true },
      }),
    },
    {
      provide: APP_FILTER,
      useClass: GlobalExceptionFilter,
    },
  ],
})
export class AppModule {}
