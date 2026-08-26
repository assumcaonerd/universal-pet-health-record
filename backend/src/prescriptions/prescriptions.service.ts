import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { createHash } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePrescriptionDto } from './dto/create-prescription.dto';
import { RecordAdherenceDto } from './dto/record-adherence.dto';

@Injectable()
export class PrescriptionsService {
  constructor(private readonly prisma: PrismaService) {}
  private hash(token: string) { return createHash('sha256').update(token).digest('hex'); }

  private async requireOwner(ownerId: string, petId: string) {
    const pet = await this.prisma.pet.findFirst({ where: { id: petId, primaryOwnerId: ownerId } });
    if (!pet) throw new NotFoundException('Pet not found');
    return pet;
  }

  private async requireVerifiedVeterinarian(userId: string, organizationId?: string) {
    const profile = await this.prisma.professionalProfile.findUnique({ where: { userId } });
    if (!profile || profile.verificationStatus !== 'VERIFIED') throw new ForbiddenException('A verified veterinarian profile is required');
    if (organizationId) {
      const membership = await this.prisma.organizationMembership.findFirst({ where: { organizationId, userId, role: { in: ['VETERINARIAN', 'ADMIN'] } } });
      if (!membership) throw new ForbiddenException('Veterinarian is not authorized for this organization');
    }
  }

  private async consumeWriteGrant(token: string, petId: string) {
    const grant = await this.prisma.accessGrant.findUnique({ where: { tokenHash: this.hash(token) } });
    if (!grant || grant.petId !== petId || grant.level !== 'WRITE') throw new ForbiddenException('Valid WRITE access is required');
    if (grant.revokedAt || grant.expiresAt <= new Date() || grant.uses >= grant.maxUses) throw new ForbiddenException('Access grant is no longer valid');
    return this.prisma.accessGrant.update({ where: { id: grant.id }, data: { uses: { increment: 1 } } });
  }

  async listForOwner(ownerId: string, petId: string) {
    await this.requireOwner(ownerId, petId);
    return this.prisma.prescription.findMany({ where: { petId }, orderBy: { prescribedAt: 'desc' } });
  }

  async recordAdherence(ownerId: string, petId: string, prescriptionId: string, dto: RecordAdherenceDto) {
    await this.requireOwner(ownerId, petId);
    const prescription = await this.prisma.prescription.findFirst({ where: { id: prescriptionId, petId } });
    if (!prescription) throw new NotFoundException('Prescription not found for this pet');
    const scheduledAt = new Date(dto.scheduledAt);
    const administeredAt = dto.status === 'TAKEN' ? new Date(dto.administeredAt ?? Date.now()) : null;
    if (dto.status === 'SKIPPED' && dto.administeredAt) throw new BadRequestException('Skipped doses cannot have administeredAt');

    const event = await this.prisma.medicationAdherenceEvent.upsert({
      where: { prescriptionId_scheduledAt: { prescriptionId, scheduledAt } },
      create: { petId, prescriptionId, recorderId: ownerId, scheduledAt, administeredAt, status: dto.status, note: dto.note, clientEventId: dto.clientEventId },
      update: { recorderId: ownerId, administeredAt, status: dto.status, note: dto.note },
    });
    await this.prisma.auditEvent.create({ data: { actorId: ownerId, action: 'MEDICATION_ADHERENCE_RECORDED', entityType: 'MedicationAdherenceEvent', entityId: event.id, metadata: { petId, prescriptionId, scheduledAt, administeredAt, status: dto.status } } });
    return event;
  }

  async adherence(ownerId: string, petId: string, prescriptionId: string) {
    await this.requireOwner(ownerId, petId);
    const prescription = await this.prisma.prescription.findFirst({ where: { id: prescriptionId, petId } });
    if (!prescription) throw new NotFoundException('Prescription not found for this pet');
    const events = await this.prisma.medicationAdherenceEvent.findMany({ where: { petId, prescriptionId }, orderBy: { scheduledAt: 'asc' } });
    const taken = events.filter((e) => e.status === 'TAKEN').length;
    const skipped = events.filter((e) => e.status === 'SKIPPED').length;
    return { prescriptionId, recorded: events.length, taken, skipped, adherencePercent: events.length ? Math.round((taken / events.length) * 1000) / 10 : null, events };
  }

  async create(veterinarianId: string, petId: string, dto: CreatePrescriptionDto) {
    await this.requireVerifiedVeterinarian(veterinarianId, dto.organizationId);
    const pet = await this.prisma.pet.findUnique({ where: { id: petId } });
    if (!pet) throw new NotFoundException('Pet not found');
    if (dto.medicalRecordId) { const record = await this.prisma.medicalRecord.findFirst({ where: { id: dto.medicalRecordId, petId } }); if (!record) throw new NotFoundException('Medical record not found for this pet'); }
    const startsAt = dto.startsAt ? new Date(dto.startsAt) : undefined;
    const endsAt = dto.endsAt ? new Date(dto.endsAt) : undefined;
    if (startsAt && endsAt && endsAt < startsAt) throw new BadRequestException('endsAt must be on or after startsAt');
    if (dto.intervalMinutes && !startsAt) throw new BadRequestException('startsAt is required when intervalMinutes is provided');
    await this.consumeWriteGrant(dto.accessToken, petId);
    return this.prisma.$transaction(async (tx) => {
      const prescription = await tx.prescription.create({ data: { petId, medicalRecordId: dto.medicalRecordId, veterinarianId, organizationId: dto.organizationId, medication: dto.medication, dosage: dto.dosage, frequency: dto.frequency, duration: dto.duration, instructions: dto.instructions, startsAt, endsAt, intervalMinutes: dto.intervalMinutes } });
      await tx.auditEvent.create({ data: { actorId: veterinarianId, action: 'PRESCRIPTION_CREATED', entityType: 'Prescription', entityId: prescription.id, metadata: { petId, medication: prescription.medication, startsAt, endsAt, intervalMinutes: dto.intervalMinutes ?? null } } });
      return prescription;
    });
  }
}
