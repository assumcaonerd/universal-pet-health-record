import { Module } from '@nestjs/common';
import { AccountController } from './account.controller';
import { AccountService } from './account.service';
import { TotpService } from './totp.service';

@Module({ controllers: [AccountController], providers: [AccountService, TotpService] })
export class AccountModule {}
