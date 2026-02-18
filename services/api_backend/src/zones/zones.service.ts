import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';

interface WeeklyFocusMap {
  [week: string]: {
    title: string;
    tasks: string[];
    tips: string[];
  };
}

@Injectable()
export class ZonesService {
  constructor(private readonly prisma: PrismaService) {}

  async getZones() {
    return this.prisma.zoneProfile.findMany({
      orderBy: [{ region: 'asc' }, { elevationBand: 'asc' }],
    });
  }

  async getWeeklyFocus(region: string, elevationBand: string, week: number) {
    const zone = await this.prisma.zoneProfile.findUnique({
      where: {
        region_elevationBand: { region, elevationBand },
      },
    });

    if (!zone) {
      throw new NotFoundException(
        `Zone profile not found for region=${region}, elevationBand=${elevationBand}`,
      );
    }

    const weeklyFocus = zone.weeklyFocus as WeeklyFocusMap;
    const weekKey = String(week);
    const focus = weeklyFocus[weekKey];

    if (!focus) {
      return {
        region,
        elevationBand,
        week,
        title: 'No focus defined for this week',
        tasks: [],
        tips: [],
      };
    }

    return {
      region,
      elevationBand,
      week,
      ...focus,
    };
  }
}
