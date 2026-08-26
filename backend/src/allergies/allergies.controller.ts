import { Body, Controller, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AllergiesService } from './allergies.service';
import { CreateAllergyDto } from './dto/create-allergy.dto';

@Controller('pets/:petId/allergies')
@UseGuards(JwtAuthGuard)
export class AllergiesController {
  constructor(private readonly allergies: AllergiesService) {}

  @Get()
  list(@Req() req: any, @Param('petId') petId: string) {
    return this.allergies.list(req.user.sub, petId);
  }

  @Post()
  create(@Req() req: any, @Param('petId') petId: string, @Body() dto: CreateAllergyDto) {
    return this.allergies.create(req.user.sub, petId, dto);
  }

  @Patch(':allergyId/deactivate')
  deactivate(@Req() req: any, @Param('petId') petId: string, @Param('allergyId') allergyId: string) {
    return this.allergies.deactivate(req.user.sub, petId, allergyId);
  }
}
