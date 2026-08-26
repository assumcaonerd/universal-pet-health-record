import { Body, Controller, Get, Param, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreatePrescriptionDto } from './dto/create-prescription.dto';
import { PrescriptionsService } from './prescriptions.service';

@Controller('pets/:petId/prescriptions')
@UseGuards(JwtAuthGuard)
export class PrescriptionsController {
  constructor(private readonly prescriptions: PrescriptionsService) {}

  @Get()
  list(@Req() req: any, @Param('petId') petId: string) {
    return this.prescriptions.listForOwner(req.user.sub, petId);
  }

  @Post()
  create(@Req() req: any, @Param('petId') petId: string, @Body() dto: CreatePrescriptionDto) {
    return this.prescriptions.create(req.user.sub, petId, dto);
  }
}
