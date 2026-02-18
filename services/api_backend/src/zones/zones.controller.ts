import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { ZonesService } from './zones.service.js';

@ApiTags('Zones')
@Controller('v1/zones')
export class ZonesController {
  constructor(private readonly zonesService: ZonesService) {}

  @Get()
  @ApiOperation({ summary: 'Get all zone profiles' })
  async getZones() {
    return this.zonesService.getZones();
  }

  @Get('weekly-focus')
  @ApiOperation({ summary: 'Get weekly focus for a zone' })
  @ApiQuery({ name: 'region', required: true, example: 'suedtirol' })
  @ApiQuery({ name: 'elevationBand', required: true, example: 'mid' })
  @ApiQuery({ name: 'week', required: true, type: Number, example: 12 })
  async getWeeklyFocus(
    @Query('region') region: string,
    @Query('elevationBand') elevationBand: string,
    @Query('week') week: string,
  ) {
    return this.zonesService.getWeeklyFocus(
      region,
      elevationBand,
      parseInt(week, 10),
    );
  }
}
