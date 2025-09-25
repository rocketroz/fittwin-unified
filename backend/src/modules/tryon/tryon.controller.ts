import { Body, Controller, Get, HttpCode, HttpStatus, Param, Post } from '@nestjs/common';
import { TryOnService } from './tryon.service';

@Controller()
export class TryOnController {
  constructor(private readonly tryOnService: TryOnService) {}

  @Post('tryon')
  async tryOn(@Body() payload: Record<string, unknown>) {
    return this.tryOnService.executeTryOn(payload);
  }

  @Get('tryon/:id')
  @HttpCode(HttpStatus.OK)
  async poll(@Param('id') id: string) {
    return this.tryOnService.pollTryOn(id);
  }
}
