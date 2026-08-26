import { ForbiddenException, Injectable } from '@nestjs/common';
import { createHash } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { CreateAllergyDto } from './dto/create-allergy.dto';

@Injectable()
export class AllergiesService {
  constructor(private readonly prisma: PrismaService) {}

  private hash(token: string) {
    return createHash('sha256').update(token).digest('hex');
  }

  private async requireOwner(petId: string, userId: string) {
    const pet = await this.prisma.pet.findFirst({ where: { id: petId, primaryOwnerId: userId } });
    if (!pet) throw new ForbiddenException('Pet access denied');
  }

  private async requireClinicalWrite(petId: string, userId: string, accessToken?: string) {
    const ownerPet = await this.prisma.pet.findFirst({ where: { id: petId, primaryOwnerId: userId } });
    if (ownerPet) return;

    const profile = await this.prisma.professionalProfile.findUnique({ where: { userId } });
    if (!profile || profile.verificationStatus !== 'VERIFIED') {
      throw new ForbiddenException('Verified veterinarian profile required');
    }
    if (!accessToken) throw new ForbiddenException('WRITE authorization token required');

    const grant = await this.prisma.accessGrant.findUnique({ where: { tokenHash: this.hash(accessToken) } });
    if (
      !grant ||
      grant.petId !== petId ||
      grant.level !== 'WRITE' ||
      grant.revokedAt ||
      grant.expiresAt <= new Date() ||
      grant.uses >= grant.maxUses
    ) {
      throw new ForbiddenException('Invalid or expired WRITE authorization');
    }

    await this.prisma.accessGrant.update({ where: { id: grant.id }, data: { uses: { increment: 1 } } });
  }

  async list(userId: string, petId: string) {
    await this.requireOwner(petId, userId);
    return this.prisma.allergy.findMany({ where: { petId }, orderBy: { createdAt: 'desc' } });
  }

  async create(userId: string, petId: string, dto: CreateAllergyDto) {
    await this.requireClinicalWrite(petId, userId, dto.accessToken);
    const allergy = await this.prisma.allergy.create({
      data: {
        petId,
        allergen: dto.allergen,
        reaction: dto.reaction,
        severity: dto.severity ?? 'MODERATE',
        authorId: userId,
      },
    });

    await this.prisma.auditEvent.create({
      data: {
        actorId: userId,
        action: 'ALLERGY_CREATED',
        entityType: 'Allergy',
        entityId: allergy.id,
        metadata: { petId, severity: allergy.severity },
      },
    });
    return allergy;
  }

  async deactivate(userId: string, petId: string, allergyId: string) {
    await this.requireOwner(petId, userId);
    const allergy = await this.prisma.allergy.findFirst({ where: { id: allergyId, petId } });
    if (!allergy) throw new ForbiddenException('Allergy not found for pet');

    const updated = await this.prisma.allergy.update({ where: { id: allergyId }, data: { active: false } });
    await this.prisma.auditEvent.create({
      data: { actorId: userId, action: 'ALLERGY_DEACTIVATED', entityType: 'Allergy', entityId: allergyId, metadata: { petId } },
    });
    return updated;
  }
}
