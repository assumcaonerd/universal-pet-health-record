import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateOrganizationDto } from './dto/create-organization.dto';

@Injectable()
export class OrganizationsService {
  constructor(private readonly prisma: PrismaService) {}

  create(actorId: string, dto: CreateOrganizationDto) {
    return this.prisma.$transaction(async (tx) => {
      const organization = await tx.organization.create({ data: dto });
      await tx.organizationMembership.create({
        data: { organizationId: organization.id, userId: actorId, role: 'ADMIN' },
      });
      await tx.auditEvent.create({
        data: { actorId, action: 'ORGANIZATION_CREATED', entityType: 'Organization', entityId: organization.id },
      });
      return organization;
    });
  }

  listForUser(userId: string) {
    return this.prisma.organization.findMany({
      where: { memberships: { some: { userId } } },
      include: { memberships: true },
      orderBy: { name: 'asc' },
    });
  }

  async getForUser(userId: string, id: string) {
    const organization = await this.prisma.organization.findFirst({
      where: { id, memberships: { some: { userId } } },
      include: { memberships: true },
    });
    if (!organization) throw new NotFoundException('Organization not found');
    return organization;
  }
}
