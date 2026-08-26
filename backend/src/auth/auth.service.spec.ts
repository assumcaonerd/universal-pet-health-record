import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import * as bcrypt from 'bcryptjs';
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

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: UsersService, useValue: users },
        { provide: JwtService, useValue: jwt },
      ],
    }).compile();
    service = module.get(AuthService);
  });

  it('registers an owner and returns a token', async () => {
    (bcrypt.hash as jest.Mock).mockResolvedValue('hash');
    users.create.mockResolvedValue({ id: 'u1', email: 'owner@example.com', role: 'OWNER', name: 'Owner' });

    const result = await service.register({ email: 'owner@example.com', name: 'Owner', password: 'strongpass' });

    expect(users.create).toHaveBeenCalledWith(expect.objectContaining({ passwordHash: 'hash' }));
    expect(result.accessToken).toBe('token');
  });

  it('rejects invalid credentials', async () => {
    users.findByEmail.mockResolvedValue(null);
    await expect(service.login({ email: 'none@example.com', password: 'strongpass' })).rejects.toThrow('Invalid credentials');
  });
});
