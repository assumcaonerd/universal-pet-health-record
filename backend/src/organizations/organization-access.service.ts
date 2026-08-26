import { ForbiddenException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AddMemberDto } from './dto/add-member.dto';

@Injectable()
export class OrganizationAccessService {
  constructor(private readonly prisma: PrismaService) {}

  async addMember(actorId: string, organizationId: string, dto: AddMemberDto) {
    const adminMembership = await this.prisma.organizationMembership.findFirst({
      where: { organizationId, userId: actorId, role: 'ADMIN' },
    });
    if (!adminMembership) throw new ForbiddenException('Organization admin required');

    const membership = await this.prisma.organizationMembership.upsert({
      where: { organizationId_userId: { organizationId, userId: dto.userId } },
      update: { role: dto.role },
      create: { organizationId, userId: dto.userId, role: dto.role },
    });

    await this.prisma.auditEvent.create({
      data: {
        actorId,
        action: 'ORGANIZATION_MEMBER_UPSERTED',
        entityType: 'OrganizationMembership',
        entityId: membership.id,
        metadata: { organizationId, userId: dto.userId, role: dto.role },
      },
    });
    return membership;
  }
}
