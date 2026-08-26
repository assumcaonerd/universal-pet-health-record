import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import * as bcrypt from 'bcryptjs';
import { EmailService } from '../email/email.service';
import { PrismaService } from '../prisma/prisma.service';
import { UsersService } from '../users/users.service';
import { AuthService } from './auth.service';

jest.mock('bcryptjs');

describe('AuthService', () => {
  let service: AuthService;
  const users = { create: jest.fn(), findByEmail: jest.fn() };
  const jwt = { signAsync: jest.fn().mockResolvedValue('token') };
  const prisma = {
    authSession: { create: jest.fn(), findUnique: jest.fn(), updateMany: jest.fn(), update: jest.fn() },
    passwordResetToken: { create: jest.fn(), findUnique: jest.fn(), update: jest.fn() },
    user: { update: jest.fn() },
    auditEvent: { create: jest.fn() },
    $transaction: jest.fn(async (value: any) => {
      if (typeof value === 'function') return value(prisma);
      return Promise.all(value);
    }),
  };
  const email = { send: jest.fn().mockResolvedValue({ delivered: true }) };

  beforeEach(async () => {
    jest.clearAllMocks();
    prisma.authSession.create.mockResolvedValue({ id: 's1' });
    prisma.auditEvent.create.mockResolvedValue({});
    const module = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: UsersService, useValue: users },
        { provide: JwtService, useValue: jwt },
        { provide: PrismaService, useValue: prisma },
        { provide: EmailService, useValue: email },
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
});
