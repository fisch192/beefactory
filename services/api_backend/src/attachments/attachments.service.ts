import { Injectable } from '@nestjs/common';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class AttachmentsService {
  private readonly s3: S3Client;
  private readonly bucket: string;

  constructor() {
    this.bucket = process.env['MINIO_BUCKET'] ?? 'bee-attachments';
    this.s3 = new S3Client({
      endpoint: process.env['MINIO_ENDPOINT'] ?? 'http://localhost:9000',
      region: process.env['MINIO_REGION'] ?? 'us-east-1',
      credentials: {
        accessKeyId: process.env['MINIO_ACCESS_KEY'] ?? 'minioadmin',
        secretAccessKey: process.env['MINIO_SECRET_KEY'] ?? 'minioadmin',
      },
      forcePathStyle: true,
    });
  }

  async generatePresignedUrl(
    userId: string,
    filename: string,
    contentType: string,
  ): Promise<{ uploadUrl: string; key: string }> {
    const ext = filename.includes('.') ? filename.split('.').pop() : 'bin';
    const key = `${userId}/${uuidv4()}.${ext}`;

    const command = new PutObjectCommand({
      Bucket: this.bucket,
      Key: key,
      ContentType: contentType,
    });

    const uploadUrl = await getSignedUrl(this.s3, command, {
      expiresIn: 3600,
    });

    return { uploadUrl, key };
  }
}
