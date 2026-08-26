import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { createHash, randomBytes } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { CreateAccessGrantDto } from './dto/create-access-grant.dto';

@Injectable()
export class AccessGrantsService {
  constructor(private readonly prisma: PrismaService) {}

  private hash(token: string) {
    return createHash('sha256').update(token).digest('hex');
  }

  async create(ownerId: string, petId: string, dto: CreateAccessGrantDto) {
    const pet = await this.prisma.pet.findFirst({ where: { id: petId, primaryOwnerId: ownerId } });
    if (!pet) throw new ForbiddenException('Only the primary owner may grant access');

    const token = randomBytes(32).toString('base64url');
    const expiresInMinutes = dto.expiresInMinutes ?? 15;
    const grant = await this.prisma.accessGrant.create({
      data: {
        petId,
        tokenHash: this.hash(token),
        level: dto.level ?? 'READ',
        expiresAt: new Date(Date.now() + expiresInMinutes * 60_000),
        maxUses: dto.maxUses ?? 1,
      },
    });

    await this.prisma.auditEvent.create({
      data: {
        actorId: ownerId,
        action: 'ACCESS_GRANT_CREATED',
        entityType: 'AccessGrant',
        entityId: grant.id,
        metadata: { petId, level: grant.level, expiresAt: grant.expiresAt.toISOString(), maxUses: grant.maxUses },
      },
    });

    return { token, grant };
  }

  async resolve(token: string) {
    const grant = await this.prisma.accessGrant.findUnique({
      where: { tokenHash: this.hash(token) },
      include: { pet: true },
    });

    if (!grant) throw new NotFoundException('Access grant not found');
    if (grant.revokedAt || grant.expiresAt <= new Date() || grant.uses >= grant.maxUses) {
      throw new ForbiddenException('Access grant is no longer valid');
    }

    const consumed = await this.prisma.accessGrant.update({
      where: { id: grant.id },
      data: { uses: { increment: 1 } },
      include: { pet: true },
    });

    await this.prisma.auditEvent.create({
      data: {
        action: 'ACCESS_GRANT_USED',
        entityType: 'AccessGrant',
        entityId: consumed.id,
        metadata: { petId: consumed.petId, uses: consumed.uses },
      },
    });

    return consumed;
  }

  async revoke(ownerId: string, grantId: string) {
    const grant = await this.prisma.accessGrant.findFirst({
      where: { id: grantId, pet: { primaryOwnerId: ownerId } },
    });
    if (!grant) throw new ForbiddenException('Only the primary owner may revoke access');

    const revoked = await this.prisma.accessGrant.update({
      where: { id: grantId },
      data: { revokedAt: new Date() },
    });
    await this.prisma.auditEvent.create({
      data: { actorId: ownerId, action: 'ACCESS_GRANT_REVOKED', entityType: 'AccessGrant', entityId: grantId },
    });
    return revoked;
  }
}
