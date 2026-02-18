import {
  IsString,
  IsOptional,
  IsInt,
  IsBoolean,
  IsUUID,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateHiveDto {
  @ApiProperty({ description: 'Site this hive belongs to' })
  @IsUUID("all")
  siteId!: string;

  @ApiProperty({ example: 1, description: 'Hive number within the site' })
  @IsInt()
  number!: number;

  @ApiPropertyOptional({ example: 'Buckfast Colony' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ example: 2024 })
  @IsOptional()
  @IsInt()
  queenYear?: number;

  @ApiPropertyOptional({ example: 'green' })
  @IsOptional()
  @IsString()
  queenColor?: string;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  queenMarked?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  notes?: string;
}
