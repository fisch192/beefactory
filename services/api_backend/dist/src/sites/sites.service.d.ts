import { PrismaService } from '../prisma/prisma.service.js';
import { CreateSiteDto } from './dto/create-site.dto.js';
import { UpdateSiteDto } from './dto/update-site.dto.js';
export declare class SitesService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    create(userId: string, dto: CreateSiteDto): Promise<{
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
    findAll(userId: string): Promise<({
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
    findOne(userId: string, id: string): Promise<{
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
    update(userId: string, id: string, dto: UpdateSiteDto): Promise<{
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
    remove(userId: string, id: string): Promise<{
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
