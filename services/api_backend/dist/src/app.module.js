"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const core_1 = require("@nestjs/core");
const throttler_1 = require("@nestjs/throttler");
const prisma_module_js_1 = require("./prisma/prisma.module.js");
const auth_module_js_1 = require("./auth/auth.module.js");
const sites_module_js_1 = require("./sites/sites.module.js");
const hives_module_js_1 = require("./hives/hives.module.js");
const events_module_js_1 = require("./events/events.module.js");
const tasks_module_js_1 = require("./tasks/tasks.module.js");
const community_module_js_1 = require("./community/community.module.js");
const zones_module_js_1 = require("./zones/zones.module.js");
const attachments_module_js_1 = require("./attachments/attachments.module.js");
const http_exception_filter_js_1 = require("./common/filters/http-exception.filter.js");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            throttler_1.ThrottlerModule.forRoot([
                {
                    ttl: 60000,
                    limit: 60,
                },
            ]),
            prisma_module_js_1.PrismaModule,
            auth_module_js_1.AuthModule,
            sites_module_js_1.SitesModule,
            hives_module_js_1.HivesModule,
            events_module_js_1.EventsModule,
            tasks_module_js_1.TasksModule,
            community_module_js_1.CommunityModule,
            zones_module_js_1.ZonesModule,
            attachments_module_js_1.AttachmentsModule,
        ],
        providers: [
            {
                provide: core_1.APP_PIPE,
                useValue: new common_1.ValidationPipe({
                    whitelist: true,
                    forbidNonWhitelisted: true,
                    transform: true,
                    transformOptions: { enableImplicitConversion: true },
                }),
            },
            {
                provide: core_1.APP_FILTER,
                useClass: http_exception_filter_js_1.GlobalExceptionFilter,
            },
        ],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map