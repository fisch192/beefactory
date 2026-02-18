import {
  IsString,
  IsOptional,
  IsInt,
  IsBoolean,
} from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateHiveDto {
  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @IsInt()
  number?: number;

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
