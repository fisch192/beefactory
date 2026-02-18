import { Module } from '@nestjs/common';
import { HivesService } from './hives.service.js';
import { HivesController } from './hives.controller.js';

@Module({
  controllers: [HivesController],
  providers: [HivesService],
  exports: [HivesService],
})
export class HivesModule {}
