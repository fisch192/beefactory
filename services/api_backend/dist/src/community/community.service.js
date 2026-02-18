"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.CommunityService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_js_1 = require("../prisma/prisma.service.js");
let CommunityService = class CommunityService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async createPost(userId, dto) {
        const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
        const recentPostCount = await this.prisma.communityPost.count({
            where: {
                userId,
                createdAt: { gte: oneHourAgo },
                deletedAt: null,
            },
        });
        if (recentPostCount >= 10) {
            throw new common_1.ForbiddenException('Rate limit exceeded: maximum 10 posts per hour');
        }
        return this.prisma.communityPost.create({
            data: {
                userId,
                region: dto.region,
                elevationBand: dto.elevationBand,
                title: dto.title,
                body: dto.body,
                tags: dto.tags ?? [],
                photoUrls: dto.photoUrls ?? [],
            },
            include: {
                user: { select: { id: true, displayName: true } },
            },
        });
    }
    async getFeed(filters) {
        const { region, elevationBand, limit = 20, cursor } = filters;
        const posts = await this.prisma.communityPost.findMany({
            where: {
                deletedAt: null,
                ...(region && { region }),
                ...(elevationBand && { elevationBand }),
            },
            orderBy: { createdAt: 'desc' },
            take: limit + 1,
            ...(cursor && {
                cursor: { id: cursor },
                skip: 1,
            }),
            include: {
                user: { select: { id: true, displayName: true } },
                _count: { select: { comments: true } },
            },
        });
        const hasMore = posts.length > limit;
        const items = hasMore ? posts.slice(0, limit) : posts;
        const nextCursor = hasMore ? items[items.length - 1].id : null;
        return {
            items,
            nextCursor,
            hasMore,
        };
    }
    async getPost(id) {
        const post = await this.prisma.communityPost.findFirst({
            where: { id, deletedAt: null },
            include: {
                user: { select: { id: true, displayName: true } },
                comments: {
                    where: { deletedAt: null },
                    orderBy: { createdAt: 'asc' },
                    include: {
                        user: { select: { id: true, displayName: true } },
                    },
                },
            },
        });
        if (!post) {
            throw new common_1.NotFoundException('Post not found');
        }
        return post;
    }
    async addComment(userId, dto) {
        const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
        const recentCommentCount = await this.prisma.communityComment.count({
            where: {
                userId,
                createdAt: { gte: oneHourAgo },
                deletedAt: null,
            },
        });
        if (recentCommentCount >= 30) {
            throw new common_1.ForbiddenException('Rate limit exceeded: maximum 30 comments per hour');
        }
        const post = await this.prisma.communityPost.findFirst({
            where: { id: dto.postId, deletedAt: null },
        });
        if (!post) {
            throw new common_1.NotFoundException('Post not found');
        }
        return this.prisma.communityComment.create({
            data: {
                postId: dto.postId,
                userId,
                body: dto.body,
                photoUrl: dto.photoUrl,
            },
            include: {
                user: { select: { id: true, displayName: true } },
            },
        });
    }
    async reportPost(userId, dto) {
        if (!dto.postId && !dto.commentId) {
            throw new common_1.BadRequestException('Either postId or commentId is required');
        }
        if (dto.postId) {
            const post = await this.prisma.communityPost.findFirst({
                where: { id: dto.postId, deletedAt: null },
            });
            if (!post) {
                throw new common_1.NotFoundException('Post not found');
            }
        }
        if (dto.commentId) {
            const comment = await this.prisma.communityComment.findFirst({
                where: { id: dto.commentId, deletedAt: null },
            });
            if (!comment) {
                throw new common_1.NotFoundException('Comment not found');
            }
        }
        return this.prisma.report.create({
            data: {
                userId,
                postId: dto.postId,
                commentId: dto.commentId,
                reason: dto.reason,
            },
        });
    }
};
exports.CommunityService = CommunityService;
exports.CommunityService = CommunityService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_js_1.PrismaService])
], CommunityService);
//# sourceMappingURL=community.service.js.map