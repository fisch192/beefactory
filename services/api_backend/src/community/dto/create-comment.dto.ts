import { IsString, IsOptional, IsUUID, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateCommentDto {
  @ApiProperty({ description: 'Post id to comment on' })
  @IsUUID("all")
  postId!: string;

  @ApiProperty({ example: 'Great advice, thanks!' })
  @IsString()
  @MaxLength(2000)
  body!: string;

  @ApiPropertyOptional({ example: 'https://storage.example.com/photo.jpg' })
  @IsOptional()
  @IsString()
  photoUrl?: string;
}
