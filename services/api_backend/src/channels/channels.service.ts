import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateChannelDto } from './dto/create-channel.dto.js';
import { CreateTopicDto } from './dto/create-topic.dto.js';
import { SendMessageDto } from './dto/send-message.dto.js';

@Injectable()
export class ChannelsService {
  constructor(private readonly prisma: PrismaService) {}

  // ---------------------------------------------------------------------------
  // Channels
  // ---------------------------------------------------------------------------

  async createChannel(userId: string, dto: CreateChannelDto) {
    const maxPos = await this.prisma.channel.aggregate({
      _max: { position: true },
      where: { deletedAt: null },
    });
    return this.prisma.channel.create({
      data: {
        name: dto.name,
        description: dto.description,
        icon: dto.icon,
        position: (maxPos._max.position ?? 0) + 1,
        createdById: userId,
      },
      include: {
        createdBy: { select: { id: true, displayName: true } },
        _count: { select: { topics: true } },
      },
    });
  }

  async listChannels() {
    return this.prisma.channel.findMany({
      where: { deletedAt: null },
      orderBy: { position: 'asc' },
      include: {
        _count: {
          select: {
            topics: { where: { deletedAt: null } },
          },
        },
      },
    });
  }

  async getChannel(id: string) {
    const channel = await this.prisma.channel.findFirst({
      where: { id, deletedAt: null },
      include: {
        createdBy: { select: { id: true, displayName: true } },
      },
    });
    if (!channel) throw new NotFoundException('Channel not found');
    return channel;
  }

  async deleteChannel(userId: string, userRole: string, id: string) {
    const channel = await this.getChannel(id);
    if (channel.createdById !== userId && userRole === 'USER') {
      throw new ForbiddenException('Only the creator or moderators can delete channels');
    }
    return this.prisma.channel.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }

  // ---------------------------------------------------------------------------
  // Topics
  // ---------------------------------------------------------------------------

  async createTopic(userId: string, dto: CreateTopicDto) {
    await this.getChannel(dto.channelId);
    return this.prisma.topic.create({
      data: {
        channelId: dto.channelId,
        title: dto.title,
        createdById: userId,
      },
      include: {
        createdBy: { select: { id: true, displayName: true } },
        _count: { select: { messages: true } },
      },
    });
  }

  async listTopics(channelId: string, cursor?: string, limit = 30) {
    await this.getChannel(channelId);

    const topics = await this.prisma.topic.findMany({
      where: { channelId, deletedAt: null },
      orderBy: [{ pinned: 'desc' }, { lastMessageAt: 'desc' }, { createdAt: 'desc' }],
      take: limit + 1,
      ...(cursor && { cursor: { id: cursor }, skip: 1 }),
      include: {
        createdBy: { select: { id: true, displayName: true } },
        _count: { select: { messages: { where: { deletedAt: null } } } },
      },
    });

    const hasMore = topics.length > limit;
    const items = hasMore ? topics.slice(0, limit) : topics;
    return {
      items,
      nextCursor: hasMore ? items[items.length - 1]!.id : null,
      hasMore,
    };
  }

  async getTopic(id: string) {
    const topic = await this.prisma.topic.findFirst({
      where: { id, deletedAt: null },
      include: {
        channel: { select: { id: true, name: true } },
        createdBy: { select: { id: true, displayName: true } },
      },
    });
    if (!topic) throw new NotFoundException('Topic not found');
    return topic;
  }

  // ---------------------------------------------------------------------------
  // Messages
  // ---------------------------------------------------------------------------

  async sendMessage(userId: string, dto: SendMessageDto) {
    const topic = await this.getTopic(dto.topicId);
    if (topic.locked) {
      throw new ForbiddenException('Topic is locked');
    }

    const message = await this.prisma.message.create({
      data: {
        topicId: dto.topicId,
        userId,
        body: dto.body,
        photoUrl: dto.photoUrl,
        replyToId: dto.replyToId,
      },
      include: {
        user: { select: { id: true, displayName: true } },
        replyTo: {
          select: {
            id: true,
            body: true,
            user: { select: { id: true, displayName: true } },
          },
        },
      },
    });

    // Update topic's lastMessageAt
    await this.prisma.topic.update({
      where: { id: dto.topicId },
      data: { lastMessageAt: new Date() },
    });

    return message;
  }

  async getMessages(topicId: string, cursor?: string, limit = 50) {
    await this.getTopic(topicId);

    const messages = await this.prisma.message.findMany({
      where: { topicId, deletedAt: null },
      orderBy: { createdAt: 'desc' },
      take: limit + 1,
      ...(cursor && { cursor: { id: cursor }, skip: 1 }),
      include: {
        user: { select: { id: true, displayName: true } },
        replyTo: {
          select: {
            id: true,
            body: true,
            user: { select: { id: true, displayName: true } },
          },
        },
      },
    });

    const hasMore = messages.length > limit;
    const items = hasMore ? messages.slice(0, limit) : messages;
    return {
      items: items.reverse(), // oldest first for chat display
      nextCursor: hasMore ? items[0]!.id : null,
      hasMore,
    };
  }

  async deleteMessage(userId: string, userRole: string, messageId: string) {
    const message = await this.prisma.message.findFirst({
      where: { id: messageId, deletedAt: null },
    });
    if (!message) throw new NotFoundException('Message not found');
    if (message.userId !== userId && userRole === 'USER') {
      throw new ForbiddenException('Only the author or moderators can delete messages');
    }
    return this.prisma.message.update({
      where: { id: messageId },
      data: { deletedAt: new Date() },
    });
  }
}
