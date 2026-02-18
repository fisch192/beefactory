import {
  IsString,
  IsOptional,
  IsArray,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreatePostDto {
  @ApiProperty({ example: 'Südtirol' })
  @IsString()
  region!: string;

  @ApiProperty({ example: 'mid' })
  @IsString()
  elevationBand!: string;

  @ApiProperty({ example: 'First spring inspection tips?' })
  @IsString()
  @MaxLength(200)
  title!: string;

  @ApiProperty({ example: 'Looking for advice on what to check...' })
  @IsString()
  @MaxLength(5000)
  body!: string;

  @ApiPropertyOptional({ example: ['inspection', 'spring'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tags?: string[];

  @ApiPropertyOptional({ example: ['https://storage.example.com/photo1.jpg'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  photoUrls?: string[];
}
