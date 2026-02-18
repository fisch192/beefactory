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
exports.CreateHiveDto = void 0;
const class_validator_1 = require("class-validator");
const swagger_1 = require("@nestjs/swagger");
class CreateHiveDto {
    siteId;
    number;
    name;
    queenYear;
    queenColor;
    queenMarked;
    notes;
}
exports.CreateHiveDto = CreateHiveDto;
__decorate([
    (0, swagger_1.ApiProperty)({ description: 'Site this hive belongs to' }),
    (0, class_validator_1.IsUUID)("all"),
    __metadata("design:type", String)
], CreateHiveDto.prototype, "siteId", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 1, description: 'Hive number within the site' }),
    (0, class_validator_1.IsInt)(),
    __metadata("design:type", Number)
], CreateHiveDto.prototype, "number", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 'Buckfast Colony' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateHiveDto.prototype, "name", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 2024 }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsInt)(),
    __metadata("design:type", Number)
], CreateHiveDto.prototype, "queenYear", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 'green' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateHiveDto.prototype, "queenColor", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ default: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsBoolean)(),
    __metadata("design:type", Boolean)
], CreateHiveDto.prototype, "queenMarked", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)(),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateHiveDto.prototype, "notes", void 0);
//# sourceMappingURL=create-hive.dto.js.map