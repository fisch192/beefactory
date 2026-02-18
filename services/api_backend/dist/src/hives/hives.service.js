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
exports.HivesService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_js_1 = require("../prisma/prisma.service.js");
let HivesService = class HivesService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async create(userId, dto) {
        const site = await this.prisma.site.findFirst({
            where: { id: dto.siteId, userId, deletedAt: null },
        });
        if (!site) {
            throw new common_1.NotFoundException('Site not found');
        }
        return this.prisma.hive.create({
            data: {
                userId,
                siteId: dto.siteId,
                number: dto.number,
                name: dto.name,
                queenYear: dto.queenYear,
                queenColor: dto.queenColor,
                queenMarked: dto.queenMarked ?? false,
                notes: dto.notes,
            },
        });
    }
    async findAll(userId, siteId) {
        return this.prisma.hive.findMany({
            where: {
                userId,
                deletedAt: null,
                ...(siteId && { siteId }),
            },
            orderBy: [{ siteId: 'asc' }, { number: 'asc' }],
            include: {
                site: { select: { id: true, name: true } },
            },
        });
    }
    async findOne(userId, id) {
        const hive = await this.prisma.hive.findFirst({
            where: { id, userId, deletedAt: null },
            include: {
                site: { select: { id: true, name: true } },
            },
        });
        if (!hive) {
            throw new common_1.NotFoundException('Hive not found');
        }
        return hive;
    }
    async update(userId, id, dto) {
        await this.findOne(userId, id);
        return this.prisma.hive.update({
            where: { id },
            data: {
                ...(dto.number !== undefined && { number: dto.number }),
                ...(dto.name !== undefined && { name: dto.name }),
                ...(dto.queenYear !== undefined && { queenYear: dto.queenYear }),
                ...(dto.queenColor !== undefined && { queenColor: dto.queenColor }),
                ...(dto.queenMarked !== undefined && { queenMarked: dto.queenMarked }),
                ...(dto.notes !== undefined && { notes: dto.notes }),
            },
        });
    }
    async remove(userId, id) {
        await this.findOne(userId, id);
        return this.prisma.hive.update({
            where: { id },
            data: { deletedAt: new Date() },
        });
    }
};
exports.HivesService = HivesService;
exports.HivesService = HivesService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_js_1.PrismaService])
], HivesService);
//# sourceMappingURL=hives.service.js.map