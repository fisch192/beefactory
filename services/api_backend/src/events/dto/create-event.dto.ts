import {
  IsString,
  IsOptional,
  IsUUID,
  IsEnum,
  IsObject,
  IsArray,
  IsDateString,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { EventType, EventSource } from '@prisma/client';

export class CreateEventDto {
  @ApiProperty({ description: 'Client-generated unique event id for idempotency' })
  @IsString()
  clientEventId!: string;

  @ApiPropertyOptional({ description: 'Hive id (optional for site-level events)' })
  @IsOptional()
  @IsUUID('all')
  hiveId?: string;

  @ApiProperty({ description: 'Site id' })
  @IsUUID('all')
  siteId!: string;

  @ApiProperty({ enum: EventType })
  @IsEnum(EventType)
  type!: EventType;

  @ApiProperty({ description: 'Local datetime string (e.g. 2024-03-15T14:30:00)', example: '2024-03-15T14:30:00' })
  @IsString()
  occurredAtLocal!: string;

  @ApiProperty({ description: 'UTC datetime', example: '2024-03-15T13:30:00.000Z' })
  @IsDateString()
  occurredAtUtc!: string;

  @ApiPropertyOptional({ description: 'Event-specific payload', default: {} })
  @IsOptional()
  @IsObject()
  payload?: Record<string, unknown>;

  @ApiPropertyOptional({ description: 'Attachment URLs', default: [] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  attachments?: string[];

  @ApiPropertyOptional({ enum: EventSource, default: EventSource.MANUAL })
  @IsOptional()
  @IsEnum(EventSource)
  source?: EventSource;
}
