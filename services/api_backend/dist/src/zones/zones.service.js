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
exports.ZonesService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_js_1 = require("../prisma/prisma.service.js");
let ZonesService = class ZonesService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getZones() {
        return this.prisma.zoneProfile.findMany({
            orderBy: [{ region: 'asc' }, { elevationBand: 'asc' }],
        });
    }
    async getWeeklyFocus(region, elevationBand, week) {
        const zone = await this.prisma.zoneProfile.findUnique({
            where: {
                region_elevationBand: { region, elevationBand },
            },
        });
        if (!zone) {
            throw new common_1.NotFoundException(`Zone profile not found for region=${region}, elevationBand=${elevationBand}`);
        }
        const weeklyFocus = zone.weeklyFocus;
        const weekKey = String(week);
        const focus = weeklyFocus[weekKey];
        if (!focus) {
            return {
                region,
                elevationBand,
                week,
                title: 'No focus defined for this week',
                tasks: [],
                tips: [],
            };
        }
        return {
            region,
            elevationBand,
            week,
            ...focus,
        };
    }
};
exports.ZonesService = ZonesService;
exports.ZonesService = ZonesService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_js_1.PrismaService])
], ZonesService);
//# sourceMappingURL=zones.service.js.map