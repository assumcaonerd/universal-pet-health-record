import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import * as bcrypt from 'bcryptjs';
import { createHash } from 'crypto';
import { EmailService } from '../email/email.service';
import { PrismaService } from '../prisma/prisma.service';
import { UsersService } from '../users/users.service';
import { AuthService } from './auth.service';
import { TotpService } from './totp.service';

jest.mock('bcryptjs');

describe('AuthService', () => {
  let service: AuthService;
  const users = { create: jest.fn(), findByEmail: jest.fn() };
  const jwt = { signAsync: jest.fn().mockResolvedValue('token') };
  const prisma: any = {
    authSession: {
      create: jest.fn(),
      findFirst: jest.fn(),
      findUnique: jest.fn(),
      updateMany: jest.fn(),
      update: jest.fn(),
    },
    totpConfiguration: { findUnique: jest.fn() },
    mfaRecoveryCode: { findUnique: jest.fn(), updateMany: jest.fn() },
    passwordResetToken: { create: jest.fn(), findUnique: jest.fn(), update: jest.fn() },
    user: { update: jest.fn() },
    auditEvent: { create: jest.fn() },
    $transaction: jest.fn(async (value: any): Promise<any> => {
      if (typeof value === 'function') return value(prisma);
      return Promise.all(value);
    }),
  };
  const email = { send: jest.fn().mockResolvedValue({ delivered: true }) };
  const totp = { decryptSecret: jest.fn().mockReturnValue('SECRET'), verify: jest.fn() };

  beforeEach(async () => {
    jest.clearAllMocks();
    prisma.authSession.create.mockResolvedValue({ id: 's1' });
    prisma.authSession.findFirst.mockResolvedValue(null);
    prisma.totpConfiguration.findUnique.mockResolvedValue(null);
    prisma.mfaRecoveryCode.findUnique.mockResolvedValue(null);
    prisma.mfaRecoveryCode.updateMany.mockResolvedValue({ count: 0 });
    prisma.auditEvent.create.mockResolvedValue({});
    const module = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: UsersService, useValue: users },
        { provide: JwtService, useValue: jwt },
        { provide: PrismaService, useValue: prisma },
        { provide: EmailService, useValue: email },
        { provide: TotpService, useValue: totp },
      ],
    }).compile();
    service = module.get(AuthService);
  });

  it('registers an owner and returns session tokens', async () => {
    (bcrypt.hash as jest.Mock).mockResolvedValue('hash');
    users.create.mockResolvedValue({ id: 'u1', email: 'owner@example.com', role: 'OWNER', name: 'Owner' });
    const result = await service.register({ email: 'owner@example.com', name: 'Owner', password: 'Strongpass!123' });
    expect(users.create).toHaveBeenCalledWith(expect.objectContaining({ passwordHash: 'hash' }));
    expect(result.accessToken).toBe('token');
    expect(result.refreshToken).toBeDefined();
    expect(result.sessionId).toBe('s1');
  });

  it('rejects invalid credentials', async () => {
    users.findByEmail.mockResolvedValue(null);
    await expect(service.login({ email: 'none@example.com', password: 'Strongpass!123' })).rejects.toThrow('Invalid credentials');
  });

  it('requires a TOTP code when MFA is enabled', async () => {
    users.findByEmail.mockResolvedValue({ id: 'u1', email: 'owner@example.com', role: 'OWNER', name: 'Owner', passwordHash: 'hash' });
    (bcrypt.compare as jest.Mock).mockResolvedValue(true);
    prisma.totpConfiguration.findUnique.mockResolvedValue({ userId: 'u1', enabledAt: new Date(), secretCiphertext: 'x', iv: 'y', authTag: 'z' });
    await expect(service.login({ email: 'owner@example.com', password: 'Strongpass!123' })).rejects.toThrow('MFA code required');
  });

  it('accepts a valid TOTP code and creates a session', async () => {
    users.findByEmail.mockResolvedValue({ id: 'u1', email: 'owner@example.com', role: 'OWNER', name: 'Owner', passwordHash: 'hash' });
    (bcrypt.compare as jest.Mock).mockResolvedValue(true);
    prisma.totpConfiguration.findUnique.mockResolvedValue({ userId: 'u1', enabledAt: new Date(), secretCiphertext: 'x', iv: 'y', authTag: 'z' });
    totp.verify.mockReturnValue(true);
    const result = await service.login({ email: 'owner@example.com', password: 'Strongpass!123', mfaCode: '123456' });
    expect(result.sessionId).toBe('s1');
    expect(totp.verify).toHaveBeenCalledWith('123456', 'SECRET');
  });

  it('consumes a valid one-time recovery code', async () => {
    users.findByEmail.mockResolvedValue({ id: 'u1', email: 'owner@example.com', role: 'OWNER', name: 'Owner', passwordHash: 'hash' });
    (bcrypt.compare as jest.Mock).mockResolvedValue(true);
    prisma.totpConfiguration.findUnique.mockResolvedValue({ userId: 'u1', enabledAt: new Date(), secretCiphertext: 'x', iv: 'y', authTag: 'z' });
    const code = 'ABCD-1234';
    prisma.mfaRecoveryCode.findUnique.mockResolvedValue({ id: 'r1', userId: 'u1', usedAt: null, codeHash: createHash('sha256').update(code).digest('hex') });
    prisma.mfaRecoveryCode.updateMany.mockResolvedValue({ count: 1 });
    const result = await service.login({ email: 'owner@example.com', password: 'Strongpass!123', recoveryCode: code });
    expect(result.sessionId).toBe('s1');
    expect(prisma.mfaRecoveryCode.updateMany).toHaveBeenCalledWith(expect.objectContaining({ where: { id: 'r1', usedAt: null } }));
  });
});
