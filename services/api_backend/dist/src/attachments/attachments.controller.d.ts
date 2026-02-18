import { AttachmentsService } from './attachments.service.js';
declare class PresignRequestDto {
    filename: string;
    contentType: string;
}
interface AuthRequest extends Express.Request {
    user: {
        id: string;
        email: string;
        role: string;
    };
}
export declare class AttachmentsController {
    private readonly attachmentsService;
    constructor(attachmentsService: AttachmentsService);
    presign(req: AuthRequest, dto: PresignRequestDto): Promise<{
        uploadUrl: string;
        key: string;
    }>;
}
export {};
