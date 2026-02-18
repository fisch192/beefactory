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
exports.CreateEventDto = void 0;
const class_validator_1 = require("class-validator");
const swagger_1 = require("@nestjs/swagger");
const client_1 = require("@prisma/client");
class CreateEventDto {
    clientEventId;
    hiveId;
    siteId;
    type;
    occurredAtLocal;
    occurredAtUtc;
    payload;
    attachments;
    source;
}
exports.CreateEventDto = CreateEventDto;
__decorate([
    (0, swagger_1.ApiProperty)({ description: 'Client-generated unique event id for idempotency' }),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateEventDto.prototype, "clientEventId", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ description: 'Hive id (optional for site-level events)' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsUUID)('all'),
    __metadata("design:type", String)
], CreateEventDto.prototype, "hiveId", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: 'Site id' }),
    (0, class_validator_1.IsUUID)('all'),
    __metadata("design:type", String)
], CreateEventDto.prototype, "siteId", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ enum: client_1.EventType }),
    (0, class_validator_1.IsEnum)(client_1.EventType),
    __metadata("design:type", String)
], CreateEventDto.prototype, "type", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: 'Local datetime string (e.g. 2024-03-15T14:30:00)', example: '2024-03-15T14:30:00' }),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateEventDto.prototype, "occurredAtLocal", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: 'UTC datetime', example: '2024-03-15T13:30:00.000Z' }),
    (0, class_validator_1.IsDateString)(),
    __metadata("design:type", String)
], CreateEventDto.prototype, "occurredAtUtc", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ description: 'Event-specific payload', default: {} }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsObject)(),
    __metadata("design:type", Object)
], CreateEventDto.prototype, "payload", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ description: 'Attachment URLs', default: [] }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsArray)(),
    (0, class_validator_1.IsString)({ each: true }),
    __metadata("design:type", Array)
], CreateEventDto.prototype, "attachments", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ enum: client_1.EventSource, default: client_1.EventSource.MANUAL }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsEnum)(client_1.EventSource),
    __metadata("design:type", String)
], CreateEventDto.prototype, "source", void 0);
//# sourceMappingURL=create-event.dto.js.map