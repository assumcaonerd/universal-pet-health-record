import { Body, Controller, Delete, Get, Param, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AccountService } from './account.service';
import { ConfirmEmailDto } from './dto/confirm-email.dto';

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
