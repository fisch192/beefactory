import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { SitesService } from './sites.service.js';
import { CreateSiteDto } from './dto/create-site.dto.js';
import { UpdateSiteDto } from './dto/update-site.dto.js';

interface AuthRequest extends Express.Request {
  user: { id: string; email: string; role: string };
}

@ApiTags('Sites')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('v1/sites')
export class SitesController {
  constructor(private readonly sitesService: SitesService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new site' })
  async create(@Request() req: AuthRequest, @Body() dto: CreateSiteDto) {
    return this.sitesService.create(req.user.id, dto);
  }

  @Get()
  @ApiOperation({ summary: 'List all sites for current user' })
  async findAll(@Request() req: AuthRequest) {
    return this.sitesService.findAll(req.user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a site by id' })
  async findOne(@Request() req: AuthRequest, @Param('id') id: string) {
    return this.sitesService.findOne(req.user.id, id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update a site' })
  async update(
    @Request() req: AuthRequest,
    @Param('id') id: string,
    @Body() dto: UpdateSiteDto,
  ) {
    return this.sitesService.update(req.user.id, id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Soft delete a site' })
  async remove(@Request() req: AuthRequest, @Param('id') id: string) {
    return this.sitesService.remove(req.user.id, id);
  }
}
