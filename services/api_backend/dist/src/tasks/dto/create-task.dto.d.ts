import { EventSource } from '@prisma/client';
export declare class CreateTaskDto {
    clientTaskId?: string;
    hiveId?: string;
    siteId?: string;
    title: string;
    description?: string;
    dueAt?: string;
    recurDays?: number;
    source?: EventSource;
}
