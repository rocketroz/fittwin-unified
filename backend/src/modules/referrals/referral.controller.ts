import { Body, Controller, Get, HttpCode, HttpStatus, Param, Post } from '@nestjs/common';
import { ReferralService } from './referral.service';

@Controller()
export class ReferralController {
  constructor(private readonly referralService: ReferralService) {}

  @Post('referrals')
  @HttpCode(HttpStatus.CREATED)
  createReferral(@Body() payload: Record<string, unknown>) {
    return this.referralService.createReferral(payload);
  }

  @Get('referrals/:rid')
  getReferral(@Param('rid') rid: string) {
    return this.referralService.getReferral(rid);
  }

  @Get('referrals/:rid/events')
  listEvents(@Param('rid') rid: string) {
    return this.referralService.listEvents(rid);
  }

  @Post('referrals/validate')
  @HttpCode(HttpStatus.OK)
  validateReferral(@Body() payload: Record<string, unknown>) {
    return this.referralService.validateReferral(payload);
  }
}
