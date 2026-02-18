import { PrismaService } from '../prisma/prisma.service.js';
export declare class ZonesService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    getZones(): Promise<{
        id: string;
        region: string;
        elevationBand: string;
        seasonStartMonth: number;
        seasonStartDay: number;
        weeklyFocus: import("@prisma/client/runtime/client").JsonValue;
    }[]>;
    getWeeklyFocus(region: string, elevationBand: string, week: number): Promise<{
        title: string;
        tasks: string[];
        tips: string[];
        region: string;
        elevationBand: string;
        week: number;
    }>;
}
