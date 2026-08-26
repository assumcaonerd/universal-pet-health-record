import { Body, Controller, Get, Param, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateVaccinationDto } from './dto/create-vaccination.dto';
import { VaccinationsService } from './vaccinations.service';

@Controller('pets/:petId/vaccinations')
@UseGuards(JwtAuthGuard)
export class VaccinationsController {
  constructor(private readonly vaccinations: VaccinationsService) {}

  @Get()
  list(@Req() req: any, @Param('petId') petId: string) {
    return this.vaccinations.listForOwner(req.user.sub, petId);
  }

  @Post()
  create(@Req() req: any, @Param('petId') petId: string, @Body() dto: CreateVaccinationDto) {
    return this.vaccinations.create(req.user.sub, petId, dto);
  }
}
