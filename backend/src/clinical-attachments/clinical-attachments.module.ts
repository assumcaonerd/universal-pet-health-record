import { Module } from '@nestjs/common';
import { ClinicalAttachmentsController } from './clinical-attachments.controller';
import { ClinicalAttachmentsService } from './clinical-attachments.service';

@Module({
  controllers: [ClinicalAttachmentsController],
  providers: [ClinicalAttachmentsService],
})
export class ClinicalAttachmentsModule {}
