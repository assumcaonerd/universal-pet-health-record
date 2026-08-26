import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { UsersService } from '../users/users.service';
import { AuthService } from './auth.service';

jest.mock('bcryptjs');

describe('AuthService', () => {
  let service: AuthService;
  const users = {
    create: jest.fn(),
    findByEmail: jest.fn(),
  };
  const jwt = { signAsync: jest.fn().mockResolvedValue('token') };
  const prisma = {
    authSession: {
      create: jest.fn().mockResolvedValue({ id: 's1' }),
      findUnique: jest.fn(),
      updateMany: jest.fn(),
      update: jest.fn(),
    },
    passwordResetToken: {
      create: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    user: { update: jest.fn() },
    auditEvent: { create: jest.fn().mockResolvedValue({}) },
    $transaction: jest.fn((input: unknown) => {
      if (typeof input === 'function') return (input as (tx: typeof prisma) => unknown)(prisma);
      return Promise.resolve(input);
    }),
  };

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
      ],
    }).compile();
    service = module.get(AuthService);
  });

  it('registers an owner and returns access and refresh tokens', async () => {
    (bcrypt.hash as jest.Mock).mockResolvedValue('hash');
    users.create.mockResolvedValue({ id: 'u1', email: 'owner@example.com', role: 'OWNER', name: 'Owner' });

    const result = await service.register({
      email: 'owner@example.com',
      name: 'Owner',
      password: 'Strongpass!123',
    });

    expect(users.create).toHaveBeenCalledWith(expect.objectContaining({ passwordHash: 'hash' }));
    expect(result.accessToken).toBe('token');
    expect(result.refreshToken).toEqual(expect.any(String));
    expect(prisma.authSession.create).toHaveBeenCalled();
  });

  it('rejects invalid credentials', async () => {
    users.findByEmail.mockResolvedValue(null);
    await expect(service.login({ email: 'none@example.com', password: 'Strongpass!123' })).rejects.toThrow(
      'Invalid credentials',
    );
  });
});
