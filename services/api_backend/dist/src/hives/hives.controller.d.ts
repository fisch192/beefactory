import { HivesService } from './hives.service.js';
import { CreateHiveDto } from './dto/create-hive.dto.js';
import { UpdateHiveDto } from './dto/update-hive.dto.js';
interface AuthRequest extends Express.Request {
    user: {
        id: string;
        email: string;
        role: string;
    };
}
export declare class HivesController {
    private readonly hivesService;
    constructor(hivesService: HivesService);
    create(req: AuthRequest, dto: CreateHiveDto): Promise<{
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
    }>;
    findAll(req: AuthRequest, siteId?: string): Promise<({
        site: {
            id: string;
            name: string;
        };
    } & {
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
    })[]>;
    findOne(req: AuthRequest, id: string): Promise<{
        site: {
            id: string;
            name: string;
        };
    } & {
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
    }>;
    update(req: AuthRequest, id: string, dto: UpdateHiveDto): Promise<{
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
    }>;
    remove(req: AuthRequest, id: string): Promise<{
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
    }>;
}
export {};
