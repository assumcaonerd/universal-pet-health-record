import { Body, Controller, Delete, Get, Param, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AccessGrantsService } from './access-grants.service';
import { CreateAccessGrantDto } from './dto/create-access-grant.dto';

@Controller('access-grants')
export class AccessGrantsController {
  constructor(private readonly grants: AccessGrantsService) {}

  @Post('pets/:petId')
  @UseGuards(JwtAuthGuard)
  create(@Req() req: any, @Param('petId') petId: string, @Body() dto: CreateAccessGrantDto) {
    return this.grants.create(req.user.sub, petId, dto);
  }

  @Get('resolve/:token')
  resolve(@Param('token') token: string) {
    return this.grants.resolve(token);
  }

  @Delete(':grantId')
  @UseGuards(JwtAuthGuard)
  revoke(@Req() req: any, @Param('grantId') grantId: string) {
    return this.grants.revoke(req.user.sub, grantId);
  }
}
