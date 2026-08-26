import { ExecutionContext } from '@nestjs/common';
import { VerifiedEmailGuard } from './verified-email.guard';

describe('VerifiedEmailGuard', () => {
  const prisma = { user: { findUnique: jest.fn() } } as any;
  const guard = new VerifiedEmailGuard(prisma);

  const context = (userId = 'u1') =>
    ({
      switchToHttp: () => ({ getRequest: () => ({ user: { sub: userId } }) }),
    }) as unknown as ExecutionContext;

  beforeEach(() => jest.clearAllMocks());

  it('allows verified users', async () => {
    prisma.user.findUnique.mockResolvedValue({ emailVerifiedAt: new Date() });
    await expect(guard.canActivate(context())).resolves.toBe(true);
  });

  it('blocks users whose email is not verified', async () => {
    prisma.user.findUnique.mockResolvedValue({ emailVerifiedAt: null });
    await expect(guard.canActivate(context())).rejects.toThrow('Email verification is required');
  });
});
