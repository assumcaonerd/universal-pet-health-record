import { ConflictException, Injectable } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  findByEmail(email: string) {
    return this.prisma.user.findUnique({ where: { email: email.toLowerCase() } });
  }

  findById(id: string) {
    return this.prisma.user.findUnique({ where: { id } });
  }

  async create(input: { email: string; name: string; passwordHash: string; role?: UserRole }) {
    const email = input.email.toLowerCase();
    if (await this.findByEmail(email)) throw new ConflictException('Email already registered');
    return this.prisma.user.create({
      data: { email, name: input.name, passwordHash: input.passwordHash, role: input.role ?? UserRole.OWNER },
    });
  }
}
