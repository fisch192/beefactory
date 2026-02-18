import { EventsService } from './events.service.js';
import { CreateEventDto } from './dto/create-event.dto.js';
import { EventType } from '@prisma/client';
interface AuthRequest extends Express.Request {
    user: {
        id: string;
        email: string;
        role: string;
    };
}
export declare class EventsController {
    private readonly eventsService;
    constructor(eventsService: EventsService);
    create(req: AuthRequest, dto: CreateEventDto): Promise<{
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
        payload: import("@prisma/client/runtime/client").JsonValue;
        attachments: import("@prisma/client/runtime/client").JsonValue;
        source: import("@prisma/client").$Enums.EventSource;
    }>;
    findAll(req: AuthRequest, siteId?: string, hiveId?: string, since?: string, type?: EventType, limit?: string, cursor?: string): Promise<{
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
            payload: import("@prisma/client/runtime/client").JsonValue;
            attachments: import("@prisma/client/runtime/client").JsonValue;
            source: import("@prisma/client").$Enums.EventSource;
        })[];
        nextCursor: string | null;
        hasMore: boolean;
    }>;
}
export {};
