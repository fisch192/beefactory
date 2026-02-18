import { IsString, IsOptional, IsUUID, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ReportDto {
  @ApiPropertyOptional({ description: 'Post id to report' })
  @IsOptional()
  @IsUUID("all")
  postId?: string;

  @ApiPropertyOptional({ description: 'Comment id to report' })
  @IsOptional()
  @IsUUID("all")
  commentId?: string;

  @ApiProperty({ example: 'Spam content' })
  @IsString()
  @MaxLength(500)
  reason!: string;
}
