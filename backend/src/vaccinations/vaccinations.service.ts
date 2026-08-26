import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { createHash } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { CreateVaccinationDto } from './dto/create-vaccination.dto';

@Injectable()
export class VaccinationsService {
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
    return this.prisma.vaccination.findMany({ where: { petId }, orderBy: { dateAdministered: 'desc' } });
  }

  async create(veterinarianId: string, petId: string, dto: CreateVaccinationDto) {
    await this.requireVerifiedVeterinarian(veterinarianId, dto.organizationId);
    const pet = await this.prisma.pet.findUnique({ where: { id: petId } });
    if (!pet) throw new NotFoundException('Pet not found');
    await this.consumeWriteGrant(dto.accessToken, petId);

    return this.prisma.$transaction(async (tx) => {
      const vaccination = await tx.vaccination.create({
        data: {
          petId,
          veterinarianId,
          organizationId: dto.organizationId,
          vaccineName: dto.vaccineName,
          manufacturer: dto.manufacturer,
          batchNumber: dto.batchNumber,
          dateAdministered: new Date(dto.dateAdministered),
          nextDueDate: dto.nextDueDate ? new Date(dto.nextDueDate) : undefined,
        },
      });
      await tx.auditEvent.create({
        data: {
          actorId: veterinarianId,
          action: 'VACCINATION_RECORDED',
          entityType: 'Vaccination',
          entityId: vaccination.id,
          metadata: { petId, vaccineName: vaccination.vaccineName },
        },
      });
      return vaccination;
    });
  }
}
