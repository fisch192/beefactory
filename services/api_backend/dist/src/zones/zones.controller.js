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
exports.ZonesController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const zones_service_js_1 = require("./zones.service.js");
let ZonesController = class ZonesController {
    zonesService;
    constructor(zonesService) {
        this.zonesService = zonesService;
    }
    async getZones() {
        return this.zonesService.getZones();
    }
    async getWeeklyFocus(region, elevationBand, week) {
        return this.zonesService.getWeeklyFocus(region, elevationBand, parseInt(week, 10));
    }
};
exports.ZonesController = ZonesController;
__decorate([
    (0, common_1.Get)(),
    (0, swagger_1.ApiOperation)({ summary: 'Get all zone profiles' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ZonesController.prototype, "getZones", null);
__decorate([
    (0, common_1.Get)('weekly-focus'),
    (0, swagger_1.ApiOperation)({ summary: 'Get weekly focus for a zone' }),
    (0, swagger_1.ApiQuery)({ name: 'region', required: true, example: 'suedtirol' }),
    (0, swagger_1.ApiQuery)({ name: 'elevationBand', required: true, example: 'mid' }),
    (0, swagger_1.ApiQuery)({ name: 'week', required: true, type: Number, example: 12 }),
    __param(0, (0, common_1.Query)('region')),
    __param(1, (0, common_1.Query)('elevationBand')),
    __param(2, (0, common_1.Query)('week')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String]),
    __metadata("design:returntype", Promise)
], ZonesController.prototype, "getWeeklyFocus", null);
exports.ZonesController = ZonesController = __decorate([
    (0, swagger_1.ApiTags)('Zones'),
    (0, common_1.Controller)('v1/zones'),
    __metadata("design:paramtypes", [zones_service_js_1.ZonesService])
], ZonesController);
//# sourceMappingURL=zones.controller.js.map