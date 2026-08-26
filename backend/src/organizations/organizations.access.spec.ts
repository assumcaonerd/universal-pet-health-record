import { ForbiddenException } from '@nestjs/common';
import { OrganizationAccessService } from './organization-access.service';

describe('OrganizationAccessService', () => {
  it('rejects membership changes from non-admins', async () => {
    const prisma: any = {
      organizationMembership: { findFirst: jest.fn().mockResolvedValue(null) },
    };
    const service = new OrganizationAccessService(prisma);

    await expect(
      service.addMember('actor', 'org', { userId: '550e8400-e29b-41d4-a716-446655440000', role: 'STAFF' }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });
});
