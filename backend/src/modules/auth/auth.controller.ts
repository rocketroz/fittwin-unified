import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('signup')
  @HttpCode(HttpStatus.ACCEPTED)
  async signup(@Body() payload: Record<string, unknown>) {
    return this.authService.signup(payload);
  }

  @Post('verify')
  @HttpCode(HttpStatus.NO_CONTENT)
  async verify(@Body() payload: Record<string, unknown>) {
    await this.authService.verify(payload);
    return;
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() payload: Record<string, unknown>) {
    return this.authService.login(payload);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  async refresh(@Body() payload: Record<string, unknown>) {
    return this.authService.refresh(payload);
  }

  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  async logout(@Body() payload: Record<string, unknown>) {
    await this.authService.logout(payload);
    return;
  }
}
