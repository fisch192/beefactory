import {
  IsString,
  IsOptional,
  IsUUID,
  IsEnum,
  IsInt,
  IsDateString,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { EventSource } from '@prisma/client';

export class CreateTaskDto {
  @ApiPropertyOptional({ description: 'Client-generated task id' })
  @IsOptional()
  @IsString()
  clientTaskId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID("all")
  hiveId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID("all")
  siteId?: string;

  @ApiProperty({ example: 'Check varroa count' })
  @IsString()
  title!: string;

  @ApiPropertyOptional({ example: 'Use sugar shake method' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ example: '2024-04-01T10:00:00.000Z' })
  @IsOptional()
  @IsDateString()
  dueAt?: string;

  @ApiPropertyOptional({ example: 14, description: 'Recurrence interval in days' })
  @IsOptional()
  @IsInt()
  recurDays?: number;

  @ApiPropertyOptional({ enum: EventSource, default: EventSource.MANUAL })
  @IsOptional()
  @IsEnum(EventSource)
  source?: EventSource;
}
