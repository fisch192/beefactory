import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { TasksService } from './tasks.service.js';
import { CreateTaskDto } from './dto/create-task.dto.js';
import { UpdateTaskDto } from './dto/update-task.dto.js';
import { TaskStatus } from '@prisma/client';

interface AuthRequest extends Express.Request {
  user: { id: string; email: string; role: string };
}

@ApiTags('Tasks')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('v1/tasks')
export class TasksController {
  constructor(private readonly tasksService: TasksService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new task' })
  async create(@Request() req: AuthRequest, @Body() dto: CreateTaskDto) {
    return this.tasksService.create(req.user.id, dto);
  }

  @Get()
  @ApiOperation({ summary: 'List tasks with filters' })
  @ApiQuery({ name: 'status', required: false, enum: TaskStatus })
  @ApiQuery({ name: 'dueFrom', required: false, description: 'ISO date string' })
  @ApiQuery({ name: 'dueTo', required: false, description: 'ISO date string' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'cursor', required: false })
  async findAll(
    @Request() req: AuthRequest,
    @Query('status') status?: TaskStatus,
    @Query('dueFrom') dueFrom?: string,
    @Query('dueTo') dueTo?: string,
    @Query('limit') limit?: string,
    @Query('cursor') cursor?: string,
  ) {
    return this.tasksService.findAll({
      userId: req.user.id,
      status,
      dueFrom,
      dueTo,
      limit: limit ? parseInt(limit, 10) : 20,
      cursor,
    });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a task by id' })
  async findOne(@Request() req: AuthRequest, @Param('id') id: string) {
    return this.tasksService.findOne(req.user.id, id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update a task' })
  async update(
    @Request() req: AuthRequest,
    @Param('id') id: string,
    @Body() dto: UpdateTaskDto,
  ) {
    return this.tasksService.update(req.user.id, id, dto);
  }
}
