import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateTaskDto } from './dto/create-task.dto.js';
import { UpdateTaskDto } from './dto/update-task.dto.js';
import { Prisma, TaskStatus } from '@prisma/client';

interface TaskFilters {
  userId: string;
  status?: TaskStatus;
  dueFrom?: string;
  dueTo?: string;
  limit?: number;
  cursor?: string;
}

@Injectable()
export class TasksService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, dto: CreateTaskDto) {
    return this.prisma.task.create({
      data: {
        clientTaskId: dto.clientTaskId,
        userId,
        hiveId: dto.hiveId,
        siteId: dto.siteId,
        title: dto.title,
        description: dto.description,
        dueAt: dto.dueAt ? new Date(dto.dueAt) : null,
        recurDays: dto.recurDays,
        source: dto.source ?? 'MANUAL',
      },
    });
  }

  async findAll(filters: TaskFilters) {
    const { userId, status, dueFrom, dueTo, limit = 20, cursor } = filters;

    const where: Prisma.TaskWhereInput = {
      userId,
      ...(status && { status }),
      ...(dueFrom || dueTo
        ? {
            dueAt: {
              ...(dueFrom && { gte: new Date(dueFrom) }),
              ...(dueTo && { lte: new Date(dueTo) }),
            },
          }
        : {}),
    };

    const tasks = await this.prisma.task.findMany({
      where,
      orderBy: [{ dueAt: 'asc' }, { createdAt: 'desc' }],
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

    const hasMore = tasks.length > limit;
    const items = hasMore ? tasks.slice(0, limit) : tasks;
    const nextCursor = hasMore ? items[items.length - 1]!.id : null;

    return {
      items,
      nextCursor,
      hasMore,
    };
  }

  async findOne(userId: string, id: string) {
    const task = await this.prisma.task.findFirst({
      where: { id, userId },
      include: {
        hive: { select: { id: true, name: true, number: true } },
        site: { select: { id: true, name: true } },
      },
    });
    if (!task) {
      throw new NotFoundException('Task not found');
    }
    return task;
  }

  async update(userId: string, id: string, dto: UpdateTaskDto) {
    await this.findOne(userId, id);
    return this.prisma.task.update({
      where: { id },
      data: {
        ...(dto.title !== undefined && { title: dto.title }),
        ...(dto.description !== undefined && { description: dto.description }),
        ...(dto.status !== undefined && { status: dto.status }),
        ...(dto.dueAt !== undefined && { dueAt: dto.dueAt ? new Date(dto.dueAt) : null }),
        ...(dto.recurDays !== undefined && { recurDays: dto.recurDays }),
      },
    });
  }

  async remove(userId: string, id: string) {
    await this.findOne(userId, id);
    return this.prisma.task.update({
      where: { id },
      data: { status: 'CANCELLED' },
    });
  }
}
