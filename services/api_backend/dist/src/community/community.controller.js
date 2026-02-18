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
exports.CommunityController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const jwt_auth_guard_js_1 = require("../auth/jwt-auth.guard.js");
const community_service_js_1 = require("./community.service.js");
const create_post_dto_js_1 = require("./dto/create-post.dto.js");
const create_comment_dto_js_1 = require("./dto/create-comment.dto.js");
const report_dto_js_1 = require("./dto/report.dto.js");
let CommunityController = class CommunityController {
    communityService;
    constructor(communityService) {
        this.communityService = communityService;
    }
    async createPost(req, dto) {
        return this.communityService.createPost(req.user.id, dto);
    }
    async getFeed(region, elevationBand, limit, cursor) {
        return this.communityService.getFeed({
            region,
            elevationBand,
            limit: limit ? parseInt(limit, 10) : 20,
            cursor,
        });
    }
    async getPost(id) {
        return this.communityService.getPost(id);
    }
    async addComment(req, dto) {
        return this.communityService.addComment(req.user.id, dto);
    }
    async report(req, dto) {
        return this.communityService.reportPost(req.user.id, dto);
    }
};
exports.CommunityController = CommunityController;
__decorate([
    (0, common_1.Post)('posts'),
    (0, swagger_1.ApiOperation)({ summary: 'Create a community post' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, create_post_dto_js_1.CreatePostDto]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "createPost", null);
__decorate([
    (0, common_1.Get)('posts'),
    (0, swagger_1.ApiOperation)({ summary: 'Get community feed' }),
    (0, swagger_1.ApiQuery)({ name: 'region', required: false }),
    (0, swagger_1.ApiQuery)({ name: 'elevationBand', required: false }),
    (0, swagger_1.ApiQuery)({ name: 'limit', required: false, type: Number }),
    (0, swagger_1.ApiQuery)({ name: 'cursor', required: false }),
    __param(0, (0, common_1.Query)('region')),
    __param(1, (0, common_1.Query)('elevationBand')),
    __param(2, (0, common_1.Query)('limit')),
    __param(3, (0, common_1.Query)('cursor')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getFeed", null);
__decorate([
    (0, common_1.Get)('posts/:id'),
    (0, swagger_1.ApiOperation)({ summary: 'Get a post with comments' }),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getPost", null);
__decorate([
    (0, common_1.Post)('comments'),
    (0, swagger_1.ApiOperation)({ summary: 'Add a comment to a post' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, create_comment_dto_js_1.CreateCommentDto]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "addComment", null);
__decorate([
    (0, common_1.Post)('reports'),
    (0, swagger_1.ApiOperation)({ summary: 'Report a post or comment' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, report_dto_js_1.ReportDto]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "report", null);
exports.CommunityController = CommunityController = __decorate([
    (0, swagger_1.ApiTags)('Community'),
    (0, swagger_1.ApiBearerAuth)(),
    (0, common_1.UseGuards)(jwt_auth_guard_js_1.JwtAuthGuard),
    (0, common_1.Controller)('v1/community'),
    __metadata("design:paramtypes", [community_service_js_1.CommunityService])
], CommunityController);
//# sourceMappingURL=community.controller.js.map