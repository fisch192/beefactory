import {
  IsString,
  IsOptional,
  IsNumber,
  IsInt,
} from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateSiteDto {
  @ApiPropertyOptional({ example: 'Bergstand Meran' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ example: 'Meran, Südtirol' })
  @IsOptional()
  @IsString()
  location?: string;

  @ApiPropertyOptional({ example: 46.6713 })
  @IsOptional()
  @IsNumber()
  latitude?: number;

  @ApiPropertyOptional({ example: 11.1535 })
  @IsOptional()
  @IsNumber()
  longitude?: number;

  @ApiPropertyOptional({ example: 600 })
  @IsOptional()
  @IsInt()
  elevation?: number;

  @ApiPropertyOptional({ example: 'Sunny location, sheltered from wind' })
  @IsOptional()
  @IsString()
  notes?: string;
}
