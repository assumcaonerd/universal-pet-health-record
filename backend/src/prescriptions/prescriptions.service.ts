import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { createHash } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePrescriptionDto } from './dto/create-prescription.dto';

@Injectable()
export class PrescriptionsService {
  constructor(private readonly prisma: PrismaService) {}

  private hash(token: string) {
    return createHash('sha256').update(token).digest('hex');
  }

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

  private async consumeWriteGrant(token: string, petId: string) {
    const grant = await this.prisma.accessGrant.findUnique({ where: { tokenHash: this.hash(token) } });
    if (!grant || grant.petId !== petId || grant.level !== 'WRITE') throw new ForbiddenException('Valid WRITE access is required');
    if (grant.revokedAt || grant.expiresAt <= new Date() || grant.uses >= grant.maxUses) {
      throw new ForbiddenException('Access grant is no longer valid');
    }
    return this.prisma.accessGrant.update({ where: { id: grant.id }, data: { uses: { increment: 1 } } });
  }

  async listForOwner(ownerId: string, petId: string) {
    const pet = await this.prisma.pet.findFirst({ where: { id: petId, primaryOwnerId: ownerId } });
    if (!pet) throw new NotFoundException('Pet not found');
    return this.prisma.prescription.findMany({ where: { petId }, orderBy: { prescribedAt: 'desc' } });
  }

  async create(veterinarianId: string, petId: string, dto: CreatePrescriptionDto) {
    await this.requireVerifiedVeterinarian(veterinarianId, dto.organizationId);
    const pet = await this.prisma.pet.findUnique({ where: { id: petId } });
    if (!pet) throw new NotFoundException('Pet not found');

    if (dto.medicalRecordId) {
      const record = await this.prisma.medicalRecord.findFirst({ where: { id: dto.medicalRecordId, petId } });
      if (!record) throw new NotFoundException('Medical record not found for this pet');
    }

    await this.consumeWriteGrant(dto.accessToken, petId);

    return this.prisma.$transaction(async (tx) => {
      const prescription = await tx.prescription.create({
        data: {
          petId,
          medicalRecordId: dto.medicalRecordId,
          veterinarianId,
          organizationId: dto.organizationId,
          medication: dto.medication,
          dosage: dto.dosage,
          frequency: dto.frequency,
          duration: dto.duration,
          instructions: dto.instructions,
        },
      });
      await tx.auditEvent.create({
        data: {
          actorId: veterinarianId,
          action: 'PRESCRIPTION_CREATED',
          entityType: 'Prescription',
          entityId: prescription.id,
          metadata: { petId, medication: prescription.medication },
        },
      });
      return prescription;
    });
  }
}
