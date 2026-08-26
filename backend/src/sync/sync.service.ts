import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { PushSyncEventDto } from './dto/push-sync-event.dto';

@Injectable()
export class SyncService {
  constructor(private readonly prisma: PrismaService) {}

  async push(userId: string, dto: PushSyncEventDto) {
    const existing = await this.prisma.syncEvent.findUnique({ where: { clientEventId: dto.clientEventId } });
    if (existing) return { accepted: false, duplicate: true, event: existing };

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

    return { accepted: true, duplicate: false, event };
  }

  pull(userId: string, after?: Date) {
    return this.prisma.syncEvent.findMany({
      where: { userId, createdAt: after ? { gt: after } : undefined },
      orderBy: { createdAt: 'asc' },
      take: 500,
    });
  }
}
