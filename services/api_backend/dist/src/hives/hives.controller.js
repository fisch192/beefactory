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
exports.HivesController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const jwt_auth_guard_js_1 = require("../auth/jwt-auth.guard.js");
const hives_service_js_1 = require("./hives.service.js");
const create_hive_dto_js_1 = require("./dto/create-hive.dto.js");
const update_hive_dto_js_1 = require("./dto/update-hive.dto.js");
let HivesController = class HivesController {
    hivesService;
    constructor(hivesService) {
        this.hivesService = hivesService;
    }
    async create(req, dto) {
        return this.hivesService.create(req.user.id, dto);
    }
    async findAll(req, siteId) {
        return this.hivesService.findAll(req.user.id, siteId);
    }
    async findOne(req, id) {
        return this.hivesService.findOne(req.user.id, id);
    }
    async update(req, id, dto) {
        return this.hivesService.update(req.user.id, id, dto);
    }
    async remove(req, id) {
        return this.hivesService.remove(req.user.id, id);
    }
};
exports.HivesController = HivesController;
__decorate([
    (0, common_1.Post)(),
    (0, swagger_1.ApiOperation)({ summary: 'Create a new hive' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, create_hive_dto_js_1.CreateHiveDto]),
    __metadata("design:returntype", Promise)
], HivesController.prototype, "create", null);
__decorate([
    (0, common_1.Get)(),
    (0, swagger_1.ApiOperation)({ summary: 'List all hives for current user' }),
    (0, swagger_1.ApiQuery)({ name: 'siteId', required: false }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('siteId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], HivesController.prototype, "findAll", null);
__decorate([
    (0, common_1.Get)(':id'),
    (0, swagger_1.ApiOperation)({ summary: 'Get a hive by id' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], HivesController.prototype, "findOne", null);
__decorate([
    (0, common_1.Put)(':id'),
    (0, swagger_1.ApiOperation)({ summary: 'Update a hive' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, update_hive_dto_js_1.UpdateHiveDto]),
    __metadata("design:returntype", Promise)
], HivesController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(':id'),
    (0, swagger_1.ApiOperation)({ summary: 'Soft delete a hive' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], HivesController.prototype, "remove", null);
exports.HivesController = HivesController = __decorate([
    (0, swagger_1.ApiTags)('Hives'),
    (0, swagger_1.ApiBearerAuth)(),
    (0, common_1.UseGuards)(jwt_auth_guard_js_1.JwtAuthGuard),
    (0, common_1.Controller)('v1/hives'),
    __metadata("design:paramtypes", [hives_service_js_1.HivesService])
], HivesController);
//# sourceMappingURL=hives.controller.js.map