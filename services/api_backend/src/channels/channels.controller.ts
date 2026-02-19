import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { ChannelsService } from './channels.service.js';
import { CreateChannelDto } from './dto/create-channel.dto.js';
import { CreateTopicDto } from './dto/create-topic.dto.js';
import { SendMessageDto } from './dto/send-message.dto.js';

interface AuthRequest extends Express.Request {
  user: { id: string; email: string; role: string };
}

@ApiTags('Channels')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('v1/channels')
export class ChannelsController {
  constructor(private readonly channelsService: ChannelsService) {}

  // ---- Channels ----

  @Post()
  @ApiOperation({ summary: 'Create a channel' })
  async createChannel(@Request() req: AuthRequest, @Body() dto: CreateChannelDto) {
    return this.channelsService.createChannel(req.user.id, dto);
  }

  @Get()
  @ApiOperation({ summary: 'List all channels' })
  async listChannels() {
    return this.channelsService.listChannels();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get channel details' })
  async getChannel(@Param('id') id: string) {
    return this.channelsService.getChannel(id);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a channel (soft-delete)' })
  async deleteChannel(@Request() req: AuthRequest, @Param('id') id: string) {
    return this.channelsService.deleteChannel(req.user.id, req.user.role, id);
  }

  // ---- Topics ----

  @Post(':channelId/topics')
  @ApiOperation({ summary: 'Create a topic in a channel' })
  async createTopic(
    @Request() req: AuthRequest,
    @Param('channelId') channelId: string,
    @Body() dto: CreateTopicDto,
  ) {
    dto.channelId = channelId;
    return this.channelsService.createTopic(req.user.id, dto);
  }

  @Get(':channelId/topics')
  @ApiOperation({ summary: 'List topics in a channel' })
  @ApiQuery({ name: 'cursor', required: false })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async listTopics(
    @Param('channelId') channelId: string,
    @Query('cursor') cursor?: string,
    @Query('limit') limit?: string,
  ) {
    return this.channelsService.listTopics(
      channelId,
      cursor,
      limit ? parseInt(limit, 10) : 30,
    );
  }

  // ---- Messages ----

  @Get('topics/:topicId/messages')
  @ApiOperation({ summary: 'Get messages in a topic' })
  @ApiQuery({ name: 'cursor', required: false })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getMessages(
    @Param('topicId') topicId: string,
    @Query('cursor') cursor?: string,
    @Query('limit') limit?: string,
  ) {
    return this.channelsService.getMessages(
      topicId,
      cursor,
      limit ? parseInt(limit, 10) : 50,
    );
  }

  @Post('topics/:topicId/messages')
  @ApiOperation({ summary: 'Send a message (REST fallback)' })
  async sendMessage(
    @Request() req: AuthRequest,
    @Param('topicId') topicId: string,
    @Body() dto: SendMessageDto,
  ) {
    dto.topicId = topicId;
    return this.channelsService.sendMessage(req.user.id, dto);
  }

  @Delete('messages/:messageId')
  @ApiOperation({ summary: 'Delete a message (soft-delete)' })
  async deleteMessage(
    @Request() req: AuthRequest,
    @Param('messageId') messageId: string,
  ) {
    return this.channelsService.deleteMessage(req.user.id, req.user.role, messageId);
  }
}
