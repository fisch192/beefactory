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
exports.SitesService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_js_1 = require("../prisma/prisma.service.js");
let SitesService = class SitesService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async create(userId, dto) {
        return this.prisma.site.create({
            data: {
                userId,
                name: dto.name,
                location: dto.location,
                latitude: dto.latitude,
                longitude: dto.longitude,
                elevation: dto.elevation,
                notes: dto.notes,
            },
        });
    }
    async findAll(userId) {
        return this.prisma.site.findMany({
            where: { userId, deletedAt: null },
            orderBy: { createdAt: 'desc' },
            include: {
                _count: { select: { hives: true } },
            },
        });
    }
    async findOne(userId, id) {
        const site = await this.prisma.site.findFirst({
            where: { id, userId, deletedAt: null },
            include: {
                hives: {
                    where: { deletedAt: null },
                    orderBy: { number: 'asc' },
                },
            },
        });
        if (!site) {
            throw new common_1.NotFoundException('Site not found');
        }
        return site;
    }
    async update(userId, id, dto) {
        await this.findOne(userId, id);
        return this.prisma.site.update({
            where: { id },
            data: {
                ...(dto.name !== undefined && { name: dto.name }),
                ...(dto.location !== undefined && { location: dto.location }),
                ...(dto.latitude !== undefined && { latitude: dto.latitude }),
                ...(dto.longitude !== undefined && { longitude: dto.longitude }),
                ...(dto.elevation !== undefined && { elevation: dto.elevation }),
                ...(dto.notes !== undefined && { notes: dto.notes }),
            },
        });
    }
    async remove(userId, id) {
        await this.findOne(userId, id);
        return this.prisma.site.update({
            where: { id },
            data: { deletedAt: new Date() },
        });
    }
};
exports.SitesService = SitesService;
exports.SitesService = SitesService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_js_1.PrismaService])
], SitesService);
//# sourceMappingURL=sites.service.js.map