import { PrismaService } from '../prisma/prisma.service.js';
import { CreateTaskDto } from './dto/create-task.dto.js';
import { UpdateTaskDto } from './dto/update-task.dto.js';
import { TaskStatus } from '@prisma/client';
interface TaskFilters {
    userId: string;
    status?: TaskStatus;
    dueFrom?: string;
    dueTo?: string;
    limit?: number;
    cursor?: string;
}
export declare class TasksService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    create(userId: string, dto: CreateTaskDto): Promise<{
        title: string;
        id: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        siteId: string | null;
        description: string | null;
        hiveId: string | null;
        source: import("@prisma/client").$Enums.EventSource;
        clientTaskId: string | null;
        dueAt: Date | null;
        recurDays: number | null;
        status: import("@prisma/client").$Enums.TaskStatus;
    }>;
    findAll(filters: TaskFilters): Promise<{
        items: ({
            site: {
                id: string;
                name: string;
            } | null;
            hive: {
                number: number;
                id: string;
                name: string | null;
            } | null;
        } & {
            title: string;
            id: string;
            createdAt: Date;
            updatedAt: Date;
            userId: string;
            siteId: string | null;
            description: string | null;
            hiveId: string | null;
            source: import("@prisma/client").$Enums.EventSource;
            clientTaskId: string | null;
            dueAt: Date | null;
            recurDays: number | null;
            status: import("@prisma/client").$Enums.TaskStatus;
        })[];
        nextCursor: string | null;
        hasMore: boolean;
    }>;
    findOne(userId: string, id: string): Promise<{
        site: {
            id: string;
            name: string;
        } | null;
        hive: {
            number: number;
            id: string;
            name: string | null;
        } | null;
    } & {
        title: string;
        id: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        siteId: string | null;
        description: string | null;
        hiveId: string | null;
        source: import("@prisma/client").$Enums.EventSource;
        clientTaskId: string | null;
        dueAt: Date | null;
        recurDays: number | null;
        status: import("@prisma/client").$Enums.TaskStatus;
    }>;
    update(userId: string, id: string, dto: UpdateTaskDto): Promise<{
        title: string;
        id: string;
        createdAt: Date;
        updatedAt: Date;
        userId: string;
        siteId: string | null;
        description: string | null;
        hiveId: string | null;
        source: import("@prisma/client").$Enums.EventSource;
        clientTaskId: string | null;
        dueAt: Date | null;
        recurDays: number | null;
        status: import("@prisma/client").$Enums.TaskStatus;
    }>;
}
export {};
