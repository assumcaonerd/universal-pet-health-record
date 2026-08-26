import { ForbiddenException } from '@nestjs/common';
import { SyncService } from './sync.service';

describe('SyncService conflict detection', () => {
  it('rejects stale pet versions', async () => {
    const prisma: any = {
      syncEvent: { findUnique: jest.fn().mockResolvedValue(null) },
      pet: { findUnique: jest.fn().mockResolvedValue({ id: 'pet', primaryOwnerId: 'owner', version: 4 }) },
    };
    const service = new SyncService(prisma);
    const result = await service.push('owner', {
      clientEventId: '550e8400-e29b-41d4-a716-446655440000',
      deviceId: 'phone-1', entityType: 'Pet', entityId: '550e8400-e29b-41d4-a716-446655440001',
      operation: 'UPDATE', version: 4,
    });
    expect(result).toMatchObject({ accepted: false, conflict: true, reason: 'STALE_VERSION', serverVersion: 4 });
  });

  it('blocks access to another owners pet', async () => {
    const prisma: any = {
      syncEvent: { findUnique: jest.fn().mockResolvedValue(null) },
      pet: { findUnique: jest.fn().mockResolvedValue({ id: 'pet', primaryOwnerId: 'other', version: 1 }) },
    };
    const service = new SyncService(prisma);
    await expect(service.push('owner', {
      clientEventId: '550e8400-e29b-41d4-a716-446655440000',
      deviceId: 'phone-1', entityType: 'Pet', entityId: '550e8400-e29b-41d4-a716-446655440001',
      operation: 'UPDATE', version: 2,
    })).rejects.toBeInstanceOf(ForbiddenException);
  });
});
