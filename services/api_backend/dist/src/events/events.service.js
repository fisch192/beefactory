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
exports.EventsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_js_1 = require("../prisma/prisma.service.js");
let EventsService = class EventsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async create(userId, dto) {
        const existing = await this.prisma.event.findUnique({
            where: {
                userId_clientEventId: {
                    userId,
                    clientEventId: dto.clientEventId,
                },
            },
        });
        if (existing) {
            return existing;
        }
        return this.prisma.event.create({
            data: {
                clientEventId: dto.clientEventId,
                userId,
                hiveId: dto.hiveId,
                siteId: dto.siteId,
                type: dto.type,
                occurredAtLocal: dto.occurredAtLocal,
                occurredAtUtc: new Date(dto.occurredAtUtc),
                payload: (dto.payload ?? {}),
                attachments: (dto.attachments ?? []),
                source: dto.source ?? 'MANUAL',
            },
        });
    }
    async findAll(filters) {
        const { userId, siteId, hiveId, since, type, limit = 20, cursor } = filters;
        const where = {
            userId,
            ...(siteId && { siteId }),
            ...(hiveId && { hiveId }),
            ...(type && { type }),
            ...(since && {
                updatedAt: { gte: new Date(since) },
            }),
        };
        const events = await this.prisma.event.findMany({
            where,
            orderBy: { occurredAtUtc: 'desc' },
            take: limit + 1,
            ...(cursor && {
                cursor: { id: cursor },
                skip: 1,
            }),
            include: {
                hive: { select: { id: true, name: true, number: true } },
                site: { select: { id: true, name: true } },
            },
        });
        const hasMore = events.length > limit;
        const items = hasMore ? events.slice(0, limit) : events;
        const nextCursor = hasMore ? items[items.length - 1].id : null;
        return {
            items,
            nextCursor,
            hasMore,
        };
    }
};
exports.EventsService = EventsService;
exports.EventsService = EventsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_js_1.PrismaService])
], EventsService);
//# sourceMappingURL=events.service.js.map