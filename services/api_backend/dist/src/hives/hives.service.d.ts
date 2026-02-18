import { PrismaService } from '../prisma/prisma.service.js';
import { CreateHiveDto } from './dto/create-hive.dto.js';
import { UpdateHiveDto } from './dto/update-hive.dto.js';
export declare class HivesService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    create(userId: string, dto: CreateHiveDto): Promise<{
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
    findAll(userId: string, siteId?: string): Promise<({
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
    findOne(userId: string, id: string): Promise<{
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
    update(userId: string, id: string, dto: UpdateHiveDto): Promise<{
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
    remove(userId: string, id: string): Promise<{
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
