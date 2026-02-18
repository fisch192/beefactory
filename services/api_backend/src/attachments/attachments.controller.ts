import {
  Controller,
  Post,
  Body,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard.js';
import { AttachmentsService } from './attachments.service.js';

class PresignRequestDto {
  @ApiProperty({ example: 'photo.jpg' })
  @IsString()
  filename!: string;

  @ApiProperty({ example: 'image/jpeg' })
  @IsString()
  contentType!: string;
}

interface AuthRequest extends Express.Request {
  user: { id: string; email: string; role: string };
}

@ApiTags('Attachments')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('v1/attachments')
export class AttachmentsController {
  constructor(private readonly attachmentsService: AttachmentsService) {}

  @Post('presign')
  @ApiOperation({ summary: 'Get a presigned URL for uploading an attachment' })
  async presign(
    @Request() req: AuthRequest,
    @Body() dto: PresignRequestDto,
  ) {
    return this.attachmentsService.generatePresignedUrl(
      req.user.id,
      dto.filename,
      dto.contentType,
    );
  }
}
