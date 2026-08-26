import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { CreateUploadIntentDto } from './dto/create-upload-intent.dto';
import { RegisterClinicalAttachmentDto } from './dto/register-clinical-attachment.dto';

@Injectable()
export class ClinicalAttachmentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
  ) {}

  private async requireOwner(petId: string, userId: string) {
    const pet = await this.prisma.pet.findFirst({ where: { id: petId, primaryOwnerId: userId } });
    if (!pet) throw new ForbiddenException('Pet access denied');
  }

  async list(userId: string, petId: string) {
    await this.requireOwner(petId, userId);
    return this.prisma.clinicalAttachment.findMany({ where: { petId }, orderBy: { createdAt: 'desc' } });
  }

  async createUploadIntent(userId: string, petId: string, dto: CreateUploadIntentDto) {
    await this.requireOwner(petId, userId);
    return this.storage.createPresignedUpload(petId, dto.fileName, dto.mimeType, dto.sha256);
  }

  async createDownloadIntent(userId: string, petId: string, attachmentId: string) {
    await this.requireOwner(petId, userId);
    const attachment = await this.prisma.clinicalAttachment.findFirst({ where: { id: attachmentId, petId } });
    if (!attachment) throw new NotFoundException('Clinical attachment not found');

    const signed = await this.storage.createPresignedDownload(
      attachment.storageKey,
      attachment.fileName,
      attachment.mimeType,
    );
    await this.prisma.auditEvent.create({
      data: {
        actorId: userId,
        action: 'CLINICAL_ATTACHMENT_DOWNLOAD_AUTHORIZED',
        entityType: 'ClinicalAttachment',
        entityId: attachment.id,
        metadata: { petId },
      },
    });
    return { ...signed, attachmentId: attachment.id, sha256: attachment.sha256, sizeBytes: attachment.sizeBytes };
  }

  async register(userId: string, petId: string, dto: RegisterClinicalAttachmentDto) {
    await this.requireOwner(petId, userId);

    if (!dto.storageKey.startsWith(`pets/${petId}/clinical/`)) {
      throw new BadRequestException('Invalid storage key for pet');
    }

    if (dto.medicalRecordId) {
      const record = await this.prisma.medicalRecord.findFirst({ where: { id: dto.medicalRecordId, petId } });
      if (!record) throw new ForbiddenException('Medical record does not belong to pet');
    }

    const verification = await this.storage.verifyObject(dto.storageKey, dto.sha256, dto.sizeBytes);
    if (!verification.hashMatches || !verification.sizeMatches) {
      throw new BadRequestException('Uploaded object integrity verification failed');
    }
    if (verification.contentType && verification.contentType !== dto.mimeType) {
      throw new BadRequestException('Uploaded object content type does not match');
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
