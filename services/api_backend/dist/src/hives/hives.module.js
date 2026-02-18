"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.HivesModule = void 0;
const common_1 = require("@nestjs/common");
const hives_service_js_1 = require("./hives.service.js");
const hives_controller_js_1 = require("./hives.controller.js");
let HivesModule = class HivesModule {
};
exports.HivesModule = HivesModule;
exports.HivesModule = HivesModule = __decorate([
    (0, common_1.Module)({
        controllers: [hives_controller_js_1.HivesController],
        providers: [hives_service_js_1.HivesService],
        exports: [hives_service_js_1.HivesService],
    })
], HivesModule);
//# sourceMappingURL=hives.module.js.map