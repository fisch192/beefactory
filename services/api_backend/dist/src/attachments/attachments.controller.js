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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AttachmentsController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const class_validator_1 = require("class-validator");
const swagger_2 = require("@nestjs/swagger");
const jwt_auth_guard_js_1 = require("../auth/jwt-auth.guard.js");
const attachments_service_js_1 = require("./attachments.service.js");
class PresignRequestDto {
    filename;
    contentType;
}
__decorate([
    (0, swagger_2.ApiProperty)({ example: 'photo.jpg' }),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], PresignRequestDto.prototype, "filename", void 0);
__decorate([
    (0, swagger_2.ApiProperty)({ example: 'image/jpeg' }),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], PresignRequestDto.prototype, "contentType", void 0);
let AttachmentsController = class AttachmentsController {
    attachmentsService;
    constructor(attachmentsService) {
        this.attachmentsService = attachmentsService;
    }
    async presign(req, dto) {
        return this.attachmentsService.generatePresignedUrl(req.user.id, dto.filename, dto.contentType);
    }
};
exports.AttachmentsController = AttachmentsController;
__decorate([
    (0, common_1.Post)('presign'),
    (0, swagger_1.ApiOperation)({ summary: 'Get a presigned URL for uploading an attachment' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, PresignRequestDto]),
    __metadata("design:returntype", Promise)
], AttachmentsController.prototype, "presign", null);
exports.AttachmentsController = AttachmentsController = __decorate([
    (0, swagger_1.ApiTags)('Attachments'),
    (0, swagger_1.ApiBearerAuth)(),
    (0, common_1.UseGuards)(jwt_auth_guard_js_1.JwtAuthGuard),
    (0, common_1.Controller)('v1/attachments'),
    __metadata("design:paramtypes", [attachments_service_js_1.AttachmentsService])
], AttachmentsController);
//# sourceMappingURL=attachments.controller.js.map