import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateEventDto } from './dto/create-event.dto.js';
import { Prisma, EventType } from '@prisma/client';

interface EventFilters {
  userId: string;
  siteId?: string;
  hiveId?: string;
  since?: string;
  type?: EventType;
  limit?: number;
  cursor?: string;
}

@Injectable()
export class EventsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, dto: CreateEventDto) {
    // Idempotency: check for existing event with same clientEventId + userId
    const existing = await this.prisma.event.findUnique({
      where: {
        userId_clientEventId: {
          userId,
          clientEventId: dto.clientEventId,
        },
      },
    });

    if (existing) {
      return existing;
    }

    return this.prisma.event.create({
      data: {
        clientEventId: dto.clientEventId,
        userId,
        hiveId: dto.hiveId,
        siteId: dto.siteId,
        type: dto.type,
        occurredAtLocal: dto.occurredAtLocal,
        occurredAtUtc: new Date(dto.occurredAtUtc),
        payload: (dto.payload ?? {}) as Prisma.InputJsonValue,
        attachments: (dto.attachments ?? []) as Prisma.InputJsonValue,
        source: dto.source ?? 'MANUAL',
      },
    });
  }

  async findAll(filters: EventFilters) {
    const { userId, siteId, hiveId, since, type, limit = 20, cursor } = filters;

    const where: Prisma.EventWhereInput = {
      userId,
      ...(siteId && { siteId }),
      ...(hiveId && { hiveId }),
      ...(type && { type }),
      ...(since && {
        updatedAt: { gte: new Date(since) },
      }),
    };

    const events = await this.prisma.event.findMany({
      where,
      orderBy: { occurredAtUtc: 'desc' },
      take: limit + 1,
      ...(cursor && {
        cursor: { id: cursor },
        skip: 1,
      }),
      include: {
        hive: { select: { id: true, name: true, number: true } },
        site: { select: { id: true, name: true } },
      },
    });

    const hasMore = events.length > limit;
    const items = hasMore ? events.slice(0, limit) : events;
    const nextCursor = hasMore ? items[items.length - 1]!.id : null;

    return {
      items,
      nextCursor,
      hasMore,
    };
  }
}
