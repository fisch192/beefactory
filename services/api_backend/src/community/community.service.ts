import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
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

@Injectable()
export class CommunityService {
  constructor(private readonly prisma: PrismaService) {}

  async createPost(userId: string, dto: CreatePostDto) {
    // Rate limiting: max 10 posts per hour per user
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const recentPostCount = await this.prisma.communityPost.count({
      where: {
        userId,
        createdAt: { gte: oneHourAgo },
        deletedAt: null,
      },
    });

    if (recentPostCount >= 10) {
      throw new ForbiddenException(
        'Rate limit exceeded: maximum 10 posts per hour',
      );
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

  async getFeed(filters: FeedFilters) {
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
    const nextCursor = hasMore ? items[items.length - 1]!.id : null;

    return {
      items,
      nextCursor,
      hasMore,
    };
  }

  async getPost(id: string) {
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
      throw new NotFoundException('Post not found');
    }
    return post;
  }

  async addComment(userId: string, dto: CreateCommentDto) {
    // Rate limiting: max 30 comments per hour per user
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const recentCommentCount = await this.prisma.communityComment.count({
      where: {
        userId,
        createdAt: { gte: oneHourAgo },
        deletedAt: null,
      },
    });

    if (recentCommentCount >= 30) {
      throw new ForbiddenException(
        'Rate limit exceeded: maximum 30 comments per hour',
      );
    }

    // Verify post exists
    const post = await this.prisma.communityPost.findFirst({
      where: { id: dto.postId, deletedAt: null },
    });
    if (!post) {
      throw new NotFoundException('Post not found');
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

  async reportPost(userId: string, dto: ReportDto) {
    if (!dto.postId && !dto.commentId) {
      throw new BadRequestException('Either postId or commentId is required');
    }

    if (dto.postId) {
      const post = await this.prisma.communityPost.findFirst({
        where: { id: dto.postId, deletedAt: null },
      });
      if (!post) {
        throw new NotFoundException('Post not found');
      }
    }

    if (dto.commentId) {
      const comment = await this.prisma.communityComment.findFirst({
        where: { id: dto.commentId, deletedAt: null },
      });
      if (!comment) {
        throw new NotFoundException('Comment not found');
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
}
