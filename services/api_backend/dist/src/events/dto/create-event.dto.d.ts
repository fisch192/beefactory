import { EventType, EventSource } from '@prisma/client';
export declare class CreateEventDto {
    clientEventId: string;
    hiveId?: string;
    siteId: string;
    type: EventType;
    occurredAtLocal: string;
    occurredAtUtc: string;
    payload?: Record<string, unknown>;
    attachments?: string[];
    source?: EventSource;
}
