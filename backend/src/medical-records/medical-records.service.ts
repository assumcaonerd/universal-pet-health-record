import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { createHash } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { AmendMedicalRecordDto } from './dto/amend-medical-record.dto';
import { CreateMedicalRecordDto } from './dto/create-medical-record.dto';

@Injectable()
export class MedicalRecordsService {
  constructor(private readonly prisma: PrismaService) {}

  private async requireVerifiedVeterinarian(userId: string, organizationId?: string) {
    const profile = await this.prisma.professionalProfile.findUnique({ where: { userId } });
    if (!profile || profile.verificationStatus !== 'VERIFIED') {
      throw new ForbiddenException('A verified veterinarian profile is required');
    }

    if (organizationId) {
      const membership = await this.prisma.organizationMembership.findFirst({
        where: { organizationId, userId, role: { in: ['VETERINARIAN', 'ADMIN'] } },
      });
      if (!membership) throw new ForbiddenException('Veterinarian is not authorized for this organization');
    }
  }

  private async requireOwner(petId: string, ownerId: string) {
    const pet = await this.prisma.pet.findFirst({ where: { id: petId, primaryOwnerId: ownerId } });
    if (!pet) throw new ForbiddenException('Pet access denied');
    return pet;
  }

  private async requireWriteGrant(petId: string, token: string) {
    const tokenHash = createHash('sha256').update(token).digest('hex');
    const grant = await this.prisma.accessGrant.findUnique({ where: { tokenHash } });
    if (
      !grant ||
      grant.petId !== petId ||
      grant.level !== 'WRITE' ||
      grant.revokedAt ||
      grant.expiresAt <= new Date() ||
      grant.uses >= grant.maxUses
    ) {
      throw new ForbiddenException('A valid owner-issued WRITE grant is required');
    }
    return grant;
  }

  async listForOwner(ownerId: string, petId: string) {
    await this.requireOwner(petId, ownerId);
    return this.prisma.medicalRecord.findMany({
      where: { petId },
      include: { versions: { orderBy: { version: 'asc' } } },
      orderBy: { occurredAt: 'desc' },
    });
  }

  async create(veterinarianId: string, petId: string, dto: CreateMedicalRecordDto) {
    await this.requireVerifiedVeterinarian(veterinarianId, dto.organizationId);
    const grant = await this.requireWriteGrant(petId, dto.accessToken);

    const pet = await this.prisma.pet.findUnique({ where: { id: petId } });
    if (!pet) throw new NotFoundException('Pet not found');

    return this.prisma.$transaction(async (tx) => {
      const record = await tx.medicalRecord.create({
        data: {
          petId,
          veterinarianId,
          organizationId: dto.organizationId,
          type: dto.type,
          diagnosis: dto.diagnosis,
          treatment: dto.treatment,
          notes: dto.notes,
          occurredAt: new Date(dto.occurredAt),
          followUpAt: dto.followUpAt ? new Date(dto.followUpAt) : undefined,
        },
      });

      await tx.medicalRecordVersion.create({
        data: {
          medicalRecordId: record.id,
          version: 1,
          diagnosis: record.diagnosis,
          treatment: record.treatment,
          notes: record.notes,
          reason: 'Initial clinical record',
          authorId: veterinarianId,
        },
      });

      await tx.accessGrant.update({ where: { id: grant.id }, data: { uses: { increment: 1 } } });
      await tx.auditEvent.create({
        data: {
          actorId: veterinarianId,
          action: 'MEDICAL_RECORD_CREATED',
          entityType: 'MedicalRecord',
          entityId: record.id,
          metadata: { petId, version: 1, accessGrantId: grant.id, followUpAt: record.followUpAt },
        },
      });

      return record;
    });
  }

  async amend(veterinarianId: string, recordId: string, dto: AmendMedicalRecordDto) {
    await this.requireVerifiedVeterinarian(veterinarianId);
    const record = await this.prisma.medicalRecord.findUnique({ where: { id: recordId } });
    if (!record) throw new NotFoundException('Medical record not found');
    if (record.veterinarianId !== veterinarianId) {
      throw new ForbiddenException('Only the authoring veterinarian may amend this record');
    }

    const nextVersion = record.currentVersion + 1;
    const diagnosis = dto.diagnosis ?? record.diagnosis;
    const treatment = dto.treatment ?? record.treatment;
    const notes = dto.notes ?? record.notes;

    return this.prisma.$transaction(async (tx) => {
      const version = await tx.medicalRecordVersion.create({
        data: {
          medicalRecordId: recordId,
          version: nextVersion,
          diagnosis,
          treatment,
          notes,
          reason: dto.reason,
          authorId: veterinarianId,
        },
      });

      await tx.medicalRecord.update({
        where: { id: recordId },
        data: { diagnosis, treatment, notes, currentVersion: nextVersion },
      });

      await tx.auditEvent.create({
        data: {
          actorId: veterinarianId,
          action: 'MEDICAL_RECORD_AMENDED',
          entityType: 'MedicalRecord',
          entityId: recordId,
          metadata: { previousVersion: record.currentVersion, version: nextVersion, reason: dto.reason },
        },
      });

      return version;
    });
  }
}
