import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateHiveDto } from './dto/create-hive.dto.js';
import { UpdateHiveDto } from './dto/update-hive.dto.js';

@Injectable()
export class HivesService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, dto: CreateHiveDto) {
    // Verify site belongs to user
    const site = await this.prisma.site.findFirst({
      where: { id: dto.siteId, userId, deletedAt: null },
    });
    if (!site) {
      throw new NotFoundException('Site not found');
    }

    return this.prisma.hive.create({
      data: {
        userId,
        siteId: dto.siteId,
        number: dto.number,
        name: dto.name,
        queenYear: dto.queenYear,
        queenColor: dto.queenColor,
        queenMarked: dto.queenMarked ?? false,
        notes: dto.notes,
      },
    });
  }

  async findAll(userId: string, siteId?: string) {
    return this.prisma.hive.findMany({
      where: {
        userId,
        deletedAt: null,
        ...(siteId && { siteId }),
      },
      orderBy: [{ siteId: 'asc' }, { number: 'asc' }],
      include: {
        site: { select: { id: true, name: true } },
      },
    });
  }

  async findOne(userId: string, id: string) {
    const hive = await this.prisma.hive.findFirst({
      where: { id, userId, deletedAt: null },
      include: {
        site: { select: { id: true, name: true } },
      },
    });
    if (!hive) {
      throw new NotFoundException('Hive not found');
    }
    return hive;
  }

  async update(userId: string, id: string, dto: UpdateHiveDto) {
    await this.findOne(userId, id);
    return this.prisma.hive.update({
      where: { id },
      data: {
        ...(dto.number !== undefined && { number: dto.number }),
        ...(dto.name !== undefined && { name: dto.name }),
        ...(dto.queenYear !== undefined && { queenYear: dto.queenYear }),
        ...(dto.queenColor !== undefined && { queenColor: dto.queenColor }),
        ...(dto.queenMarked !== undefined && { queenMarked: dto.queenMarked }),
        ...(dto.notes !== undefined && { notes: dto.notes }),
      },
    });
  }

  async remove(userId: string, id: string) {
    await this.findOne(userId, id);
    return this.prisma.hive.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }
}
