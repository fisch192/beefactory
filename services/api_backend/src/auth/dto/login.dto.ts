import { IsEmail, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class LoginDto {
  @ApiProperty({ example: 'user@bee.app' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'securepass1' })
  @IsString()
  password!: string;
}
