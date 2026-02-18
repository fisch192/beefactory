import { CommunityService } from './community.service.js';
import { CreatePostDto } from './dto/create-post.dto.js';
import { CreateCommentDto } from './dto/create-comment.dto.js';
import { ReportDto } from './dto/report.dto.js';
interface AuthRequest extends Express.Request {
    user: {
        id: string;
        email: string;
        role: string;
    };
}
export declare class CommunityController {
    private readonly communityService;
    constructor(communityService: CommunityService);
    createPost(req: AuthRequest, dto: CreatePostDto): Promise<{
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
    getFeed(region?: string, elevationBand?: string, limit?: string, cursor?: string): Promise<{
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
    addComment(req: AuthRequest, dto: CreateCommentDto): Promise<{
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
    report(req: AuthRequest, dto: ReportDto): Promise<{
        id: string;
        createdAt: Date;
        userId: string;
        postId: string | null;
        commentId: string | null;
        reason: string;
    }>;
}
export {};
