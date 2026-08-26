import { ForbiddenException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterClinicalAttachmentDto } from './dto/register-clinical-attachment.dto';

@Injectable()
export class ClinicalAttachmentsService {
  constructor(private readonly prisma: PrismaService) {}

  private async requireOwner(petId: string, userId: string) {
    const pet = await this.prisma.pet.findFirst({ where: { id: petId, primaryOwnerId: userId } });
    if (!pet) throw new ForbiddenException('Pet access denied');
  }

  async list(userId: string, petId: string) {
    await this.requireOwner(petId, userId);
    return this.prisma.clinicalAttachment.findMany({ where: { petId }, orderBy: { createdAt: 'desc' } });
  }

  async register(userId: string, petId: string, dto: RegisterClinicalAttachmentDto) {
    await this.requireOwner(petId, userId);

    if (dto.medicalRecordId) {
      const record = await this.prisma.medicalRecord.findFirst({ where: { id: dto.medicalRecordId, petId } });
      if (!record) throw new ForbiddenException('Medical record does not belong to pet');
    }

    const attachment = await this.prisma.clinicalAttachment.create({
      data: {
        petId,
        medicalRecordId: dto.medicalRecordId,
        authorId: userId,
        fileName: dto.fileName,
        mimeType: dto.mimeType,
        storageKey: dto.storageKey,
        sha256: dto.sha256.toLowerCase(),
        sizeBytes: dto.sizeBytes,
      },
    });

    await this.prisma.auditEvent.create({
      data: {
        actorId: userId,
        action: 'CLINICAL_ATTACHMENT_REGISTERED',
        entityType: 'ClinicalAttachment',
        entityId: attachment.id,
        metadata: { petId, medicalRecordId: dto.medicalRecordId ?? null, sha256: attachment.sha256 },
      },
    });

    return attachment;
  }
}
