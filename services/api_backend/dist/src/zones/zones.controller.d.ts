import { ZonesService } from './zones.service.js';
export declare class ZonesController {
    private readonly zonesService;
    constructor(zonesService: ZonesService);
    getZones(): Promise<{
        id: string;
        region: string;
        elevationBand: string;
        seasonStartMonth: number;
        seasonStartDay: number;
        weeklyFocus: import("@prisma/client/runtime/client").JsonValue;
    }[]>;
    getWeeklyFocus(region: string, elevationBand: string, week: string): Promise<{
        title: string;
        tasks: string[];
        tips: string[];
        region: string;
        elevationBand: string;
        week: number;
    }>;
}
