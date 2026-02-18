import { TaskStatus } from '@prisma/client';
export declare class UpdateTaskDto {
    title?: string;
    description?: string;
    status?: TaskStatus;
    dueAt?: string;
    recurDays?: number;
}
