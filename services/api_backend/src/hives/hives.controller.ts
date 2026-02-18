import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { HivesService } from './hives.service.js';
import { CreateHiveDto } from './dto/create-hive.dto.js';
import { UpdateHiveDto } from './dto/update-hive.dto.js';

interface AuthRequest extends Express.Request {
  user: { id: string; email: string; role: string };
}

@ApiTags('Hives')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('v1/hives')
export class HivesController {
  constructor(private readonly hivesService: HivesService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new hive' })
  async create(@Request() req: AuthRequest, @Body() dto: CreateHiveDto) {
    return this.hivesService.create(req.user.id, dto);
  }

  @Get()
  @ApiOperation({ summary: 'List all hives for current user' })
  @ApiQuery({ name: 'siteId', required: false })
  async findAll(
    @Request() req: AuthRequest,
    @Query('siteId') siteId?: string,
  ) {
    return this.hivesService.findAll(req.user.id, siteId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a hive by id' })
  async findOne(@Request() req: AuthRequest, @Param('id') id: string) {
    return this.hivesService.findOne(req.user.id, id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update a hive' })
  async update(
    @Request() req: AuthRequest,
    @Param('id') id: string,
    @Body() dto: UpdateHiveDto,
  ) {
    return this.hivesService.update(req.user.id, id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Soft delete a hive' })
  async remove(@Request() req: AuthRequest, @Param('id') id: string) {
    return this.hivesService.remove(req.user.id, id);
  }
}
