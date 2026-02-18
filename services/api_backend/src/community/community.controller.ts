import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { CommunityService } from './community.service.js';
import { CreatePostDto } from './dto/create-post.dto.js';
import { CreateCommentDto } from './dto/create-comment.dto.js';
import { ReportDto } from './dto/report.dto.js';

interface AuthRequest extends Express.Request {
  user: { id: string; email: string; role: string };
}

@ApiTags('Community')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('v1/community')
export class CommunityController {
  constructor(private readonly communityService: CommunityService) {}

  @Post('posts')
  @ApiOperation({ summary: 'Create a community post' })
  async createPost(@Request() req: AuthRequest, @Body() dto: CreatePostDto) {
    return this.communityService.createPost(req.user.id, dto);
  }

  @Get('posts')
  @ApiOperation({ summary: 'Get community feed' })
  @ApiQuery({ name: 'region', required: false })
  @ApiQuery({ name: 'elevationBand', required: false })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'cursor', required: false })
  async getFeed(
    @Query('region') region?: string,
    @Query('elevationBand') elevationBand?: string,
    @Query('limit') limit?: string,
    @Query('cursor') cursor?: string,
  ) {
    return this.communityService.getFeed({
      region,
      elevationBand,
      limit: limit ? parseInt(limit, 10) : 20,
      cursor,
    });
  }

  @Get('posts/:id')
  @ApiOperation({ summary: 'Get a post with comments' })
  async getPost(@Param('id') id: string) {
    return this.communityService.getPost(id);
  }

  @Post('comments')
  @ApiOperation({ summary: 'Add a comment to a post' })
  async addComment(
    @Request() req: AuthRequest,
    @Body() dto: CreateCommentDto,
  ) {
    return this.communityService.addComment(req.user.id, dto);
  }

  @Post('reports')
  @ApiOperation({ summary: 'Report a post or comment' })
  async report(@Request() req: AuthRequest, @Body() dto: ReportDto) {
    return this.communityService.reportPost(req.user.id, dto);
  }
}
