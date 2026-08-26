import { Body, Controller, Post, Req } from '@nestjs/common';
import { Request } from 'express';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { PasswordResetConfirmDto } from './dto/password-reset-confirm.dto';
import { PasswordResetRequestDto } from './dto/password-reset-request.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RegisterDto } from './dto/register.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  private requestContext(req: Request) {
    const deviceIdHeader = req.headers['x-device-id'];
    return {
      deviceId: Array.isArray(deviceIdHeader) ? deviceIdHeader[0] : deviceIdHeader,
      userAgent: req.headers['user-agent'],
      ipAddress: req.ip,
    };
  }

  @Post('register')
  register(@Body() dto: RegisterDto, @Req() req: Request) {
    return this.auth.register(dto, this.requestContext(req));
  }

  @Post('login')
  login(@Body() dto: LoginDto, @Req() req: Request) {
    return this.auth.login(dto, this.requestContext(req));
  }

  @Post('refresh')
  refresh(@Body() dto: RefreshTokenDto, @Req() req: Request) {
    return this.auth.refresh(dto, this.requestContext(req));
  }

  @Post('logout')
  logout(@Body() dto: RefreshTokenDto) {
    return this.auth.logout(dto);
  }

  @Post('password-reset/request')
  requestPasswordReset(@Body() dto: PasswordResetRequestDto) {
    return this.auth.requestPasswordReset(dto);
  }

  @Post('password-reset/confirm')
  confirmPasswordReset(@Body() dto: PasswordResetConfirmDto) {
    return this.auth.confirmPasswordReset(dto);
  }
}
