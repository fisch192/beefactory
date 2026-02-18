"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AttachmentsService = void 0;
const common_1 = require("@nestjs/common");
const client_s3_1 = require("@aws-sdk/client-s3");
const s3_request_presigner_1 = require("@aws-sdk/s3-request-presigner");
const uuid_1 = require("uuid");
let AttachmentsService = class AttachmentsService {
    s3;
    bucket;
    constructor() {
        this.bucket = process.env['MINIO_BUCKET'] ?? 'bee-attachments';
        this.s3 = new client_s3_1.S3Client({
            endpoint: process.env['MINIO_ENDPOINT'] ?? 'http://localhost:9000',
            region: process.env['MINIO_REGION'] ?? 'us-east-1',
            credentials: {
                accessKeyId: process.env['MINIO_ACCESS_KEY'] ?? 'minioadmin',
                secretAccessKey: process.env['MINIO_SECRET_KEY'] ?? 'minioadmin',
            },
            forcePathStyle: true,
        });
    }
    async generatePresignedUrl(userId, filename, contentType) {
        const ext = filename.includes('.') ? filename.split('.').pop() : 'bin';
        const key = `${userId}/${(0, uuid_1.v4)()}.${ext}`;
        const command = new client_s3_1.PutObjectCommand({
            Bucket: this.bucket,
            Key: key,
            ContentType: contentType,
        });
        const uploadUrl = await (0, s3_request_presigner_1.getSignedUrl)(this.s3, command, {
            expiresIn: 3600,
        });
        return { uploadUrl, key };
    }
};
exports.AttachmentsService = AttachmentsService;
exports.AttachmentsService = AttachmentsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [])
], AttachmentsService);
//# sourceMappingURL=attachments.service.js.map