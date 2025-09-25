import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, Post, Put } from '@nestjs/common';
import { ProfileService } from './profile.service';
import { AvatarService } from './avatar.service';

@Controller()
export class ProfileController {
  constructor(
    private readonly profileService: ProfileService,
    private readonly avatarService: AvatarService
  ) {}

  @Get('me')
  async getProfile() {
    return this.profileService.getProfile();
  }

  @Put('me/profile')
  async updateProfile(@Body() payload: Record<string, unknown>) {
    return this.profileService.updateProfile(payload);
  }

  @Put('me/body')
  async updateBody(@Body() payload: Record<string, unknown>) {
    return this.profileService.updateBodyMetrics(payload);
  }

  @Post('me/export')
  @HttpCode(HttpStatus.ACCEPTED)
  async requestExport() {
    return this.profileService.requestExport();
  }

  @Delete('me')
  @HttpCode(HttpStatus.ACCEPTED)
  async deleteProfile() {
    return this.profileService.deleteProfile();
  }

  @Post('me/avatar')
  @HttpCode(HttpStatus.ACCEPTED)
  async createAvatar(@Body() payload: Record<string, unknown>) {
    return this.avatarService.createAvatarJob(payload);
  }

  @Get('me/avatar/:avatarId')
  async getAvatar(@Param('avatarId') avatarId: string) {
    return this.avatarService.getAvatarStatus(avatarId);
  }

  @Delete('me/avatar/:avatarId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteAvatar(@Param('avatarId') avatarId: string) {
    await this.avatarService.deleteAvatar(avatarId);
    return;
  }

  @Post('me/addresses')
  @HttpCode(HttpStatus.CREATED)
  async createAddress(@Body() payload: Record<string, unknown>) {
    return this.profileService.addAddress(payload);
  }

  @Post('me/payment-methods')
  @HttpCode(HttpStatus.CREATED)
  async createPaymentMethod(@Body() payload: Record<string, unknown>) {
    return this.profileService.addPaymentMethod(payload);
  }
}
