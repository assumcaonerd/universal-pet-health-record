import { Body, Controller, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AmendMedicalRecordDto } from './dto/amend-medical-record.dto';
import { CreateMedicalRecordDto } from './dto/create-medical-record.dto';
import { MedicalRecordsService } from './medical-records.service';

@Controller()
@UseGuards(JwtAuthGuard)
export class MedicalRecordsController {
  constructor(private readonly records: MedicalRecordsService) {}

  @Get('pets/:petId/medical-records')
  list(@Req() req: any, @Param('petId') petId: string) {
    return this.records.listForOwner(req.user.sub, petId);
  }

  @Post('pets/:petId/medical-records')
  create(@Req() req: any, @Param('petId') petId: string, @Body() dto: CreateMedicalRecordDto) {
    return this.records.create(req.user.sub, petId, dto);
  }

  @Patch('medical-records/:recordId/amend')
  amend(@Req() req: any, @Param('recordId') recordId: string, @Body() dto: AmendMedicalRecordDto) {
    return this.records.amend(req.user.sub, recordId, dto);
  }
}
