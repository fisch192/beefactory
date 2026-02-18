import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { EventsService } from './events.service.js';
import { CreateEventDto } from './dto/create-event.dto.js';
import { EventType } from '@prisma/client';

interface AuthRequest extends Express.Request {
  user: { id: string; email: string; role: string };
}

@ApiTags('Events')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('v1/events')
export class EventsController {
  constructor(private readonly eventsService: EventsService) {}

  @Post()
  @ApiOperation({ summary: 'Create an event (idempotent via clientEventId)' })
  async create(@Request() req: AuthRequest, @Body() dto: CreateEventDto) {
    return this.eventsService.create(req.user.id, dto);
  }

  @Get()
  @ApiOperation({ summary: 'List events with filters and cursor pagination' })
  @ApiQuery({ name: 'siteId', required: false })
  @ApiQuery({ name: 'hiveId', required: false })
  @ApiQuery({ name: 'since', required: false, description: 'ISO date string, filter by updatedAt >= since' })
  @ApiQuery({ name: 'type', required: false, enum: EventType })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'cursor', required: false })
  async findAll(
    @Request() req: AuthRequest,
    @Query('siteId') siteId?: string,
    @Query('hiveId') hiveId?: string,
    @Query('since') since?: string,
    @Query('type') type?: EventType,
    @Query('limit') limit?: string,
    @Query('cursor') cursor?: string,
  ) {
    return this.eventsService.findAll({
      userId: req.user.id,
      siteId,
      hiveId,
      since,
      type,
      limit: limit ? parseInt(limit, 10) : 20,
      cursor,
    });
  }
}
