import { Controller, Get, Query } from '@nestjs/common';
import { AnalyticsService } from './analytics.service';

@Controller()
export class AnalyticsController {
  constructor(private readonly analyticsService: AnalyticsService) {}

  @Get('brand/analytics')
  getBrandAnalytics(
    @Query('brandId') brandId?: string,
    @Query('rangeStart') rangeStart?: string,
    @Query('rangeEnd') rangeEnd?: string,
    @Query('granularity') granularity?: string
  ) {
    return this.analyticsService.getBrandAnalytics({ brandId, rangeStart, rangeEnd, granularity });
  }
}
