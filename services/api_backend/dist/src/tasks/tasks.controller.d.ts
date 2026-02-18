import { TasksService } from './tasks.service.js';
import { CreateTaskDto } from './dto/create-task.dto.js';
import { UpdateTaskDto } from './dto/update-task.dto.js';
import { TaskStatus } from '@prisma/client';
interface AuthRequest extends Express.Request {
    user: {
        id: string;
        email: string;
        role: string;
    };
}
export declare class TasksController {
    private readonly tasksService;
    constructor(tasksService: TasksService);
    create(req: AuthRequest, dto: CreateTaskDto): Promise<{
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
    findAll(req: AuthRequest, status?: TaskStatus, dueFrom?: string, dueTo?: string, limit?: string, cursor?: string): Promise<{
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
    findOne(req: AuthRequest, id: string): Promise<{
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
    update(req: AuthRequest, id: string, dto: UpdateTaskDto): Promise<{
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
