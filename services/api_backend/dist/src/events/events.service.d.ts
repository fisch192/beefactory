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
export declare class EventsService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    create(userId: string, dto: CreateEventDto): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        siteId: string;
        type: import("@prisma/client").$Enums.EventType;
        clientEventId: string;
        hiveId: string | null;
        occurredAtLocal: string;
        occurredAtUtc: Date;
        payload: Prisma.JsonValue;
        attachments: Prisma.JsonValue;
        source: import("@prisma/client").$Enums.EventSource;
    }>;
    findAll(filters: EventFilters): Promise<{
        items: ({
            site: {
                id: string;
                name: string;
            };
            hive: {
                number: number;
                id: string;
                name: string | null;
            } | null;
        } & {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            userId: string;
            siteId: string;
            type: import("@prisma/client").$Enums.EventType;
            clientEventId: string;
            hiveId: string | null;
            occurredAtLocal: string;
            occurredAtUtc: Date;
            payload: Prisma.JsonValue;
            attachments: Prisma.JsonValue;
            source: import("@prisma/client").$Enums.EventSource;
        })[];
        nextCursor: string | null;
        hasMore: boolean;
    }>;
}
export {};
