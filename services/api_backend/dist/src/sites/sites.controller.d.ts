import { SitesService } from './sites.service.js';
import { CreateSiteDto } from './dto/create-site.dto.js';
import { UpdateSiteDto } from './dto/update-site.dto.js';
interface AuthRequest extends Express.Request {
    user: {
        id: string;
        email: string;
        role: string;
    };
}
export declare class SitesController {
    private readonly sitesService;
    constructor(sitesService: SitesService);
    create(req: AuthRequest, dto: CreateSiteDto): Promise<{
        id: string;
        name: string;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        location: string | null;
        latitude: number | null;
        longitude: number | null;
        elevation: number | null;
        notes: string | null;
    }>;
    findAll(req: AuthRequest): Promise<({
        _count: {
            hives: number;
        };
    } & {
        id: string;
        name: string;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        location: string | null;
        latitude: number | null;
        longitude: number | null;
        elevation: number | null;
        notes: string | null;
    })[]>;
    findOne(req: AuthRequest, id: string): Promise<{
        hives: {
            number: number;
            id: string;
            name: string | null;
            createdAt: Date;
            updatedAt: Date;
            deletedAt: Date | null;
            userId: string;
            notes: string | null;
            queenYear: number | null;
            queenColor: string | null;
            queenMarked: boolean;
            siteId: string;
        }[];
    } & {
        id: string;
        name: string;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        location: string | null;
        latitude: number | null;
        longitude: number | null;
        elevation: number | null;
        notes: string | null;
    }>;
    update(req: AuthRequest, id: string, dto: UpdateSiteDto): Promise<{
        id: string;
        name: string;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        location: string | null;
        latitude: number | null;
        longitude: number | null;
        elevation: number | null;
        notes: string | null;
    }>;
    remove(req: AuthRequest, id: string): Promise<{
        id: string;
        name: string;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        location: string | null;
        latitude: number | null;
        longitude: number | null;
        elevation: number | null;
        notes: string | null;
    }>;
}
export {};
