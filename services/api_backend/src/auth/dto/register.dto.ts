import { IsEmail, IsString, MinLength, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class RegisterDto {
  @ApiProperty({ example: 'user@bee.app' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'securepass1', minLength: 8 })
  @IsString()
  @MinLength(8)
  password!: string;

  @ApiPropertyOptional({ example: 'Max Mustermann' })
  @IsOptional()
  @IsString()
  displayName?: string;
}
