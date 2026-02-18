import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateSiteDto } from './dto/create-site.dto.js';
import { UpdateSiteDto } from './dto/update-site.dto.js';

@Injectable()
export class SitesService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, dto: CreateSiteDto) {
    return this.prisma.site.create({
      data: {
        userId,
        name: dto.name,
        location: dto.location,
        latitude: dto.latitude,
        longitude: dto.longitude,
        elevation: dto.elevation,
        notes: dto.notes,
      },
    });
  }

  async findAll(userId: string) {
    return this.prisma.site.findMany({
      where: { userId, deletedAt: null },
      orderBy: { createdAt: 'desc' },
      include: {
        _count: { select: { hives: true } },
      },
    });
  }

  async findOne(userId: string, id: string) {
    const site = await this.prisma.site.findFirst({
      where: { id, userId, deletedAt: null },
      include: {
        hives: {
          where: { deletedAt: null },
          orderBy: { number: 'asc' },
        },
      },
    });
    if (!site) {
      throw new NotFoundException('Site not found');
    }
    return site;
  }

  async update(userId: string, id: string, dto: UpdateSiteDto) {
    await this.findOne(userId, id);
    return this.prisma.site.update({
      where: { id },
      data: {
        ...(dto.name !== undefined && { name: dto.name }),
        ...(dto.location !== undefined && { location: dto.location }),
        ...(dto.latitude !== undefined && { latitude: dto.latitude }),
        ...(dto.longitude !== undefined && { longitude: dto.longitude }),
        ...(dto.elevation !== undefined && { elevation: dto.elevation }),
        ...(dto.notes !== undefined && { notes: dto.notes }),
      },
    });
  }

  async remove(userId: string, id: string) {
    await this.findOne(userId, id);
    return this.prisma.site.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }
}
