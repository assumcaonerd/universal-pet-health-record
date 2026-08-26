import { Body, Controller, Get, Put, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UpsertProfessionalProfileDto } from './dto/upsert-professional-profile.dto';
import { ProfessionalsService } from './professionals.service';

@Controller('professionals')
@UseGuards(JwtAuthGuard)
export class ProfessionalsController {
  constructor(private readonly professionals: ProfessionalsService) {}

  @Put('me')
  upsert(@Req() req: any, @Body() dto: UpsertProfessionalProfileDto) {
    return this.professionals.upsert(req.user.sub, dto);
  }

  @Get('me')
  getMine(@Req() req: any) {
    return this.professionals.getMine(req.user.sub);
  }
}
