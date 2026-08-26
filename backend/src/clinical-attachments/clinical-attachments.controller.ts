import { Body, Controller, Get, Param, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ClinicalAttachmentsService } from './clinical-attachments.service';
import { RegisterClinicalAttachmentDto } from './dto/register-clinical-attachment.dto';

@Controller('pets/:petId/attachments')
@UseGuards(JwtAuthGuard)
export class ClinicalAttachmentsController {
  constructor(private readonly attachments: ClinicalAttachmentsService) {}

  @Get()
  list(@Req() req: any, @Param('petId') petId: string) {
    return this.attachments.list(req.user.sub, petId);
  }

  @Post('register')
  register(@Req() req: any, @Param('petId') petId: string, @Body() dto: RegisterClinicalAttachmentDto) {
    return this.attachments.register(req.user.sub, petId, dto);
  }
}
