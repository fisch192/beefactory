export declare class AttachmentsService {
    private readonly s3;
    private readonly bucket;
    constructor();
    generatePresignedUrl(userId: string, filename: string, contentType: string): Promise<{
        uploadUrl: string;
        key: string;
    }>;
}
