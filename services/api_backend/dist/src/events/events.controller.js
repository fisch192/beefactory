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
exports.EventsController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const jwt_auth_guard_js_1 = require("../auth/jwt-auth.guard.js");
const events_service_js_1 = require("./events.service.js");
const create_event_dto_js_1 = require("./dto/create-event.dto.js");
const client_1 = require("@prisma/client");
let EventsController = class EventsController {
    eventsService;
    constructor(eventsService) {
        this.eventsService = eventsService;
    }
    async create(req, dto) {
        return this.eventsService.create(req.user.id, dto);
    }
    async findAll(req, siteId, hiveId, since, type, limit, cursor) {
        return this.eventsService.findAll({
            userId: req.user.id,
            siteId,
            hiveId,
            since,
            type,
            limit: limit ? parseInt(limit, 10) : 20,
            cursor,
        });
    }
};
exports.EventsController = EventsController;
__decorate([
    (0, common_1.Post)(),
    (0, swagger_1.ApiOperation)({ summary: 'Create an event (idempotent via clientEventId)' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, create_event_dto_js_1.CreateEventDto]),
    __metadata("design:returntype", Promise)
], EventsController.prototype, "create", null);
__decorate([
    (0, common_1.Get)(),
    (0, swagger_1.ApiOperation)({ summary: 'List events with filters and cursor pagination' }),
    (0, swagger_1.ApiQuery)({ name: 'siteId', required: false }),
    (0, swagger_1.ApiQuery)({ name: 'hiveId', required: false }),
    (0, swagger_1.ApiQuery)({ name: 'since', required: false, description: 'ISO date string, filter by updatedAt >= since' }),
    (0, swagger_1.ApiQuery)({ name: 'type', required: false, enum: client_1.EventType }),
    (0, swagger_1.ApiQuery)({ name: 'limit', required: false, type: Number }),
    (0, swagger_1.ApiQuery)({ name: 'cursor', required: false }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('siteId')),
    __param(2, (0, common_1.Query)('hiveId')),
    __param(3, (0, common_1.Query)('since')),
    __param(4, (0, common_1.Query)('type')),
    __param(5, (0, common_1.Query)('limit')),
    __param(6, (0, common_1.Query)('cursor')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, String, String, String, String]),
    __metadata("design:returntype", Promise)
], EventsController.prototype, "findAll", null);
exports.EventsController = EventsController = __decorate([
    (0, swagger_1.ApiTags)('Events'),
    (0, swagger_1.ApiBearerAuth)(),
    (0, common_1.UseGuards)(jwt_auth_guard_js_1.JwtAuthGuard),
    (0, common_1.Controller)('v1/events'),
    __metadata("design:paramtypes", [events_service_js_1.EventsService])
], EventsController);
//# sourceMappingURL=events.controller.js.map