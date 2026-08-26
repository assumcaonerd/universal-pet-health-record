import { ForbiddenException, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { PushSyncEventDto } from './dto/push-sync-event.dto';

@Injectable()
export class SyncService {
  constructor(private readonly prisma: PrismaService) {}

  private petPatch(payload?: Record<string, unknown>) {
    if (!payload) return {};
    const allowed = ['name', 'breed', 'birthDate', 'microchip'] as const;
    const patch: Record<string, unknown> = {};
    for (const key of allowed) {
      if (Object.prototype.hasOwnProperty.call(payload, key)) patch[key] = payload[key];
    }
    if (typeof patch.birthDate === 'string') patch.birthDate = new Date(patch.birthDate);
    return patch;
  }

  async push(userId: string, dto: PushSyncEventDto) {
    const existing = await this.prisma.syncEvent.findUnique({ where: { clientEventId: dto.clientEventId } });
    if (existing) return { accepted: false, duplicate: true, conflict: false, event: existing };

    if (dto.entityType.toLowerCase() === 'pet') {
      const pet = await this.prisma.pet.findUnique({ where: { id: dto.entityId } });
      if (!pet || pet.primaryOwnerId !== userId) throw new ForbiddenException('Pet access denied');

      if (!dto.version) {
        return { accepted: false, duplicate: false, conflict: true, reason: 'VERSION_REQUIRED', serverVersion: pet.version };
      }
      if (dto.version <= pet.version) {
        return { accepted: false, duplicate: false, conflict: true, reason: 'STALE_VERSION', serverVersion: pet.version };
      }
      if (dto.version > pet.version + 1) {
        return { accepted: false, duplicate: false, conflict: true, reason: 'VERSION_GAP', serverVersion: pet.version };
      }

      const competing = await this.prisma.syncEvent.findFirst({
        where: { entityType: dto.entityType, entityId: dto.entityId, version: dto.version },
      });
      if (competing) {
        return {
          accepted: false,
          duplicate: false,
          conflict: true,
          reason: 'CONCURRENT_VERSION',
          serverVersion: pet.version,
          competingEventId: competing.id,
        };
      }

      if (dto.operation.toUpperCase() === 'UPDATE') {
        const patch = this.petPatch(dto.payload);
        try {
          const result = await this.prisma.$transaction(async (tx) => {
            const updated = await tx.pet.updateMany({
              where: { id: dto.entityId, primaryOwnerId: userId, version: pet.version },
              data: { ...patch, version: { increment: 1 } } as Prisma.PetUpdateManyMutationInput,
            });
            if (updated.count !== 1) return null;

            const event = await tx.syncEvent.create({
              data: {
                clientEventId: dto.clientEventId,
                userId,
                deviceId: dto.deviceId,
                entityType: dto.entityType,
                entityId: dto.entityId,
                operation: dto.operation,
                version: dto.version,
                payload: dto.payload as Prisma.InputJsonValue | undefined,
              },
            });
            await tx.auditEvent.create({
              data: {
                actorId: userId,
                action: 'PET_SYNC_APPLIED',
                entityType: 'Pet',
                entityId: dto.entityId,
                metadata: { clientEventId: dto.clientEventId, deviceId: dto.deviceId, version: dto.version },
              },
            });
            return event;
          });
          if (!result) {
            const current = await this.prisma.pet.findUnique({ where: { id: dto.entityId } });
            return {
              accepted: false,
              duplicate: false,
              conflict: true,
              reason: 'OPTIMISTIC_LOCK_FAILED',
              serverVersion: current?.version,
            };
          }
          return { accepted: true, duplicate: false, conflict: false, applied: true, event: result };
        } catch (error) {
          if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
            const duplicate = await this.prisma.syncEvent.findUnique({ where: { clientEventId: dto.clientEventId } });
            return { accepted: false, duplicate: true, conflict: false, event: duplicate };
          }
          throw error;
        }
      }
    }

    const event = await this.prisma.syncEvent.create({
      data: {
        clientEventId: dto.clientEventId,
        userId,
        deviceId: dto.deviceId,
        entityType: dto.entityType,
        entityId: dto.entityId,
        operation: dto.operation,
        version: dto.version,
        payload: dto.payload as Prisma.InputJsonValue | undefined,
      },
    });

    return { accepted: true, duplicate: false, conflict: false, applied: false, event };
  }

  pull(userId: string, after?: Date) {
    return this.prisma.syncEvent.findMany({
      where: { userId, createdAt: after ? { gt: after } : undefined },
      orderBy: { createdAt: 'asc' },
      take: 500,
    });
  }
}
