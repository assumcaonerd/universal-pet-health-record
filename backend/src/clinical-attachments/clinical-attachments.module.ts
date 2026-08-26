import { Module } from '@nestjs/common';
import { StorageModule } from '../storage/storage.module';
import { ClinicalAttachmentsController } from './clinical-attachments.controller';
import { ClinicalAttachmentsService } from './clinical-attachments.service';

@Module({
  imports: [StorageModule],
  controllers: [ClinicalAttachmentsController],
  providers: [ClinicalAttachmentsService],
})
export class ClinicalAttachmentsModule {}
