import { ForbiddenException, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { PushSyncEventDto } from './dto/push-sync-event.dto';

@Injectable()
export class SyncService {
  constructor(private readonly prisma: PrismaService) {}

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

    return { accepted: true, duplicate: false, conflict: false, event };
  }

  pull(userId: string, after?: Date) {
    return this.prisma.syncEvent.findMany({
      where: { userId, createdAt: after ? { gt: after } : undefined },
      orderBy: { createdAt: 'asc' },
      take: 500,
    });
  }
}
