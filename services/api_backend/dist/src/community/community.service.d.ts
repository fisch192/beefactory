import { PrismaService } from '../prisma/prisma.service.js';
import { CreatePostDto } from './dto/create-post.dto.js';
import { CreateCommentDto } from './dto/create-comment.dto.js';
import { ReportDto } from './dto/report.dto.js';
interface FeedFilters {
    region?: string;
    elevationBand?: string;
    limit?: number;
    cursor?: string;
}
export declare class CommunityService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    createPost(userId: string, dto: CreatePostDto): Promise<{
        user: {
            id: string;
            displayName: string | null;
        };
    } & {
        title: string;
        id: string;
        region: string;
        elevationBand: string;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        tags: string[];
        body: string;
        photoUrls: string[];
    }>;
    getFeed(filters: FeedFilters): Promise<{
        items: ({
            user: {
                id: string;
                displayName: string | null;
            };
            _count: {
                comments: number;
            };
        } & {
            title: string;
            id: string;
            region: string;
            elevationBand: string;
            createdAt: Date;
            updatedAt: Date;
            deletedAt: Date | null;
            userId: string;
            tags: string[];
            body: string;
            photoUrls: string[];
        })[];
        nextCursor: string | null;
        hasMore: boolean;
    }>;
    getPost(id: string): Promise<{
        comments: ({
            user: {
                id: string;
                displayName: string | null;
            };
        } & {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            deletedAt: Date | null;
            userId: string;
            body: string;
            postId: string;
            photoUrl: string | null;
        })[];
        user: {
            id: string;
            displayName: string | null;
        };
    } & {
        title: string;
        id: string;
        region: string;
        elevationBand: string;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        tags: string[];
        body: string;
        photoUrls: string[];
    }>;
    addComment(userId: string, dto: CreateCommentDto): Promise<{
        user: {
            id: string;
            displayName: string | null;
        };
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        body: string;
        postId: string;
        photoUrl: string | null;
    }>;
    reportPost(userId: string, dto: ReportDto): Promise<{
        id: string;
        createdAt: Date;
        userId: string;
        postId: string | null;
        commentId: string | null;
        reason: string;
    }>;
}
export {};
