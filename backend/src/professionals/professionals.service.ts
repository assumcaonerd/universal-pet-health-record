import { ForbiddenException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpsertProfessionalProfileDto } from './dto/upsert-professional-profile.dto';

@Injectable()
export class ProfessionalsService {
  constructor(private readonly prisma: PrismaService) {}

  async upsert(userId: string, dto: UpsertProfessionalProfileDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new ForbiddenException('User not found');

    const profile = await this.prisma.professionalProfile.upsert({
      where: { userId },
      update: {
        licenseNumber: dto.licenseNumber,
        licenseState: dto.licenseState.toUpperCase(),
        specialty: dto.specialty,
      },
      create: {
        userId,
        licenseNumber: dto.licenseNumber,
        licenseState: dto.licenseState.toUpperCase(),
        specialty: dto.specialty,
      },
    });

    await this.prisma.auditEvent.create({
      data: {
        actorId: userId,
        action: 'PROFESSIONAL_PROFILE_UPSERTED',
        entityType: 'ProfessionalProfile',
        entityId: profile.id,
      },
    });

    return profile;
  }

  getMine(userId: string) {
    return this.prisma.professionalProfile.findUnique({ where: { userId } });
  }
}
