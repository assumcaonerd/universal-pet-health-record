import { Body, Controller, Delete, Get, Param, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { VerifiedEmailGuard } from '../auth/verified-email.guard';
import { AccountService } from './account.service';
import { ConfirmEmailDto } from './dto/confirm-email.dto';
import { MfaCodeDto } from './dto/mfa-code.dto';

@Controller('account')
export class AccountController {
  constructor(private readonly account: AccountService) {}

  @Post('email-verification/confirm')
  confirmEmail(@Body() dto: ConfirmEmailDto) {
    return this.account.confirmEmail(dto.token);
  }

  @Post('email-verification/request')
  @UseGuards(JwtAuthGuard)
  requestEmailVerification(@Req() req: any) {
    return this.account.requestEmailVerification(req.user.sub);
  }

  @Get('security')
  @UseGuards(JwtAuthGuard)
  securitySummary(@Req() req: any) {
    return this.account.getSecuritySummary(req.user.sub);
  }

  @Get('mfa')
  @UseGuards(JwtAuthGuard)
  getMfaStatus(@Req() req: any) {
    return this.account.getMfaStatus(req.user.sub);
  }

  @Post('mfa/setup')
  @UseGuards(JwtAuthGuard, VerifiedEmailGuard)
  setupMfa(@Req() req: any) {
    return this.account.setupMfa(req.user.sub);
  }

  @Post('mfa/confirm')
  @UseGuards(JwtAuthGuard, VerifiedEmailGuard)
  confirmMfa(@Req() req: any, @Body() dto: MfaCodeDto) {
    return this.account.confirmMfa(req.user.sub, dto.code);
  }

  @Post('mfa/recovery-codes/regenerate')
  @UseGuards(JwtAuthGuard, VerifiedEmailGuard)
  regenerateRecoveryCodes(@Req() req: any, @Body() dto: MfaCodeDto) {
    return this.account.regenerateRecoveryCodes(req.user.sub, dto.code);
  }

  @Delete('mfa')
  @UseGuards(JwtAuthGuard, VerifiedEmailGuard)
  disableMfa(@Req() req: any, @Body() dto: MfaCodeDto) {
    return this.account.disableMfa(req.user.sub, dto.code);
  }

  @Get('sessions')
  @UseGuards(JwtAuthGuard)
  listSessions(@Req() req: any) {
    return this.account.listSessions(req.user.sub);
  }

  @Delete('sessions/:sessionId')
  @UseGuards(JwtAuthGuard)
  revokeSession(@Req() req: any, @Param('sessionId') sessionId: string) {
    return this.account.revokeSession(req.user.sub, sessionId);
  }
}
