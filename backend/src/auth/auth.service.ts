import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { createHash, randomBytes } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { UsersService } from '../users/users.service';
import { LoginDto } from './dto/login.dto';
import { PasswordResetConfirmDto } from './dto/password-reset-confirm.dto';
import { PasswordResetRequestDto } from './dto/password-reset-request.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RegisterDto } from './dto/register.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly users: UsersService,
    private readonly jwt: JwtService,
    private readonly prisma: PrismaService,
  ) {}

  private hashToken(token: string) {
    return createHash('sha256').update(token).digest('hex');
  }

  private createOpaqueToken() {
    return randomBytes(48).toString('base64url');
  }

  async register(dto: RegisterDto, context?: { deviceId?: string; userAgent?: string; ipAddress?: string }) {
    const passwordHash = await bcrypt.hash(dto.password, 12);
    const user = await this.users.create({ email: dto.email, name: dto.name, passwordHash });
    return this.issueSession(user.id, user.email, user.role, user.name, context);
  }

  async login(dto: LoginDto, context?: { deviceId?: string; userAgent?: string; ipAddress?: string }) {
    const user = await this.users.findByEmail(dto.email);
    if (!user || !(await bcrypt.compare(dto.password, user.passwordHash))) {
      throw new UnauthorizedException('Invalid credentials');
    }
    return this.issueSession(user.id, user.email, user.role, user.name, context);
  }

  async refresh(dto: RefreshTokenDto, context?: { userAgent?: string; ipAddress?: string }) {
    const hash = this.hashToken(dto.refreshToken);
    const session = await this.prisma.authSession.findUnique({ where: { refreshTokenHash: hash }, include: { user: true } });
    if (!session || session.revokedAt || session.expiresAt <= new Date()) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    const nextRefreshToken = this.createOpaqueToken();
    const nextHash = this.hashToken(nextRefreshToken);
    const nextExpiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    const rotated = await this.prisma.$transaction(async (tx) => {
      const updated = await tx.authSession.updateMany({
        where: { id: session.id, revokedAt: null, refreshTokenHash: hash },
        data: {
          refreshTokenHash: nextHash,
          expiresAt: nextExpiresAt,
          userAgent: context?.userAgent ?? session.userAgent,
          ipAddress: context?.ipAddress ?? session.ipAddress,
        },
      });
      if (updated.count !== 1) return false;
      await tx.auditEvent.create({
        data: {
          actorId: session.userId,
          action: 'AUTH_SESSION_REFRESHED',
          entityType: 'AuthSession',
          entityId: session.id,
        },
      });
      return true;
    });
    if (!rotated) throw new UnauthorizedException('Refresh token already rotated or revoked');

    const accessToken = await this.jwt.signAsync({ sub: session.user.id, email: session.user.email, role: session.user.role });
    return {
      accessToken,
      refreshToken: nextRefreshToken,
      expiresInSeconds: 3600,
      refreshExpiresAt: nextExpiresAt.toISOString(),
      user: { id: session.user.id, email: session.user.email, role: session.user.role, name: session.user.name },
    };
  }

  async logout(dto: RefreshTokenDto) {
    const hash = this.hashToken(dto.refreshToken);
    const session = await this.prisma.authSession.findUnique({ where: { refreshTokenHash: hash } });
    if (!session) return { revoked: true };
    if (!session.revokedAt) {
      await this.prisma.$transaction([
        this.prisma.authSession.update({ where: { id: session.id }, data: { revokedAt: new Date() } }),
        this.prisma.auditEvent.create({
          data: {
            actorId: session.userId,
            action: 'AUTH_SESSION_REVOKED',
            entityType: 'AuthSession',
            entityId: session.id,
          },
        }),
      ]);
    }
    return { revoked: true };
  }

  async requestPasswordReset(dto: PasswordResetRequestDto) {
    const user = await this.users.findByEmail(dto.email);
    if (!user) return { accepted: true };

    const token = this.createOpaqueToken();
    const tokenHash = this.hashToken(token);
    const expiresAt = new Date(Date.now() + 30 * 60 * 1000);
    await this.prisma.passwordResetToken.create({ data: { userId: user.id, tokenHash, expiresAt } });
    await this.prisma.auditEvent.create({
      data: { actorId: user.id, action: 'PASSWORD_RESET_REQUESTED', entityType: 'User', entityId: user.id },
    });

    if (process.env.NODE_ENV !== 'production') return { accepted: true, developmentToken: token, expiresAt: expiresAt.toISOString() };
    return { accepted: true };
  }

  async confirmPasswordReset(dto: PasswordResetConfirmDto) {
    const tokenHash = this.hashToken(dto.token);
    const reset = await this.prisma.passwordResetToken.findUnique({ where: { tokenHash } });
    if (!reset || reset.usedAt || reset.expiresAt <= new Date()) {
      throw new UnauthorizedException('Invalid or expired reset token');
    }

    const passwordHash = await bcrypt.hash(dto.newPassword, 12);
    await this.prisma.$transaction([
      this.prisma.user.update({ where: { id: reset.userId }, data: { passwordHash } }),
      this.prisma.passwordResetToken.update({ where: { id: reset.id }, data: { usedAt: new Date() } }),
      this.prisma.authSession.updateMany({ where: { userId: reset.userId, revokedAt: null }, data: { revokedAt: new Date() } }),
      this.prisma.auditEvent.create({
        data: { actorId: reset.userId, action: 'PASSWORD_RESET_COMPLETED', entityType: 'User', entityId: reset.userId },
      }),
    ]);
    return { changed: true, sessionsRevoked: true };
  }

  private async issueSession(
    id: string,
    email: string,
    role: string,
    name: string,
    context?: { deviceId?: string; userAgent?: string; ipAddress?: string },
  ) {
    const accessToken = await this.jwt.signAsync({ sub: id, email, role });
    const refreshToken = this.createOpaqueToken();
    const refreshTokenHash = this.hashToken(refreshToken);
    const refreshExpiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    const session = await this.prisma.authSession.create({
      data: {
        userId: id,
        refreshTokenHash,
        deviceId: context?.deviceId,
        userAgent: context?.userAgent,
        ipAddress: context?.ipAddress,
        expiresAt: refreshExpiresAt,
      },
    });
    await this.prisma.auditEvent.create({
      data: { actorId: id, action: 'AUTH_SESSION_CREATED', entityType: 'AuthSession', entityId: session.id },
    });
    return {
      accessToken,
      refreshToken,
      expiresInSeconds: 3600,
      refreshExpiresAt: refreshExpiresAt.toISOString(),
      user: { id, email, role, name },
    };
  }
}
