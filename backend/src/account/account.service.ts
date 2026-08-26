import { ForbiddenException, Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { createHash, randomBytes } from 'crypto';
import { EmailService } from '../email/email.service';
import { PrismaService } from '../prisma/prisma.service';
import { TotpService } from './totp.service';

@Injectable()
export class AccountService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly email: EmailService,
    private readonly totp: TotpService,
  ) {}

  private hashToken(token: string) {
    return createHash('sha256').update(token).digest('hex');
  }

  async requestEmailVerification(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    if (user.emailVerifiedAt) return { accepted: true, alreadyVerified: true };

    const token = randomBytes(48).toString('base64url');
    const tokenHash = this.hashToken(token);
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

    await this.prisma.emailVerificationToken.create({ data: { userId, tokenHash, expiresAt } });
    const baseUrl = process.env.APP_PUBLIC_URL ?? 'http://localhost:3000';
    const verificationUrl = `${baseUrl}/verify-email?token=${encodeURIComponent(token)}`;
    await this.email.send(user.email, 'Verifique seu e-mail', `Confirme seu e-mail: ${verificationUrl}`);
    await this.prisma.auditEvent.create({
      data: { actorId: userId, action: 'EMAIL_VERIFICATION_REQUESTED', entityType: 'User', entityId: userId },
    });

    return process.env.NODE_ENV === 'production'
      ? { accepted: true, expiresAt: expiresAt.toISOString() }
      : { accepted: true, developmentToken: token, expiresAt: expiresAt.toISOString() };
  }

  async confirmEmail(token: string) {
    const tokenHash = this.hashToken(token);
    const verification = await this.prisma.emailVerificationToken.findUnique({ where: { tokenHash } });
    if (!verification || verification.usedAt || verification.expiresAt <= new Date()) {
      throw new UnauthorizedException('Invalid or expired verification token');
    }

    await this.prisma.$transaction([
      this.prisma.user.update({ where: { id: verification.userId }, data: { emailVerifiedAt: new Date() } }),
      this.prisma.emailVerificationToken.update({ where: { id: verification.id }, data: { usedAt: new Date() } }),
      this.prisma.auditEvent.create({
        data: {
          actorId: verification.userId,
          action: 'EMAIL_VERIFIED',
          entityType: 'User',
          entityId: verification.userId,
        },
      }),
    ]);
    return { verified: true };
  }

  async getMfaStatus(userId: string) {
    const configuration = await this.prisma.totpConfiguration.findUnique({
      where: { userId },
      select: { enabledAt: true, createdAt: true, updatedAt: true },
    });
    return {
      configured: Boolean(configuration),
      enabled: Boolean(configuration?.enabledAt),
      enabledAt: configuration?.enabledAt ?? null,
    };
  }

  async setupMfa(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { email: true, emailVerifiedAt: true },
    });
    if (!user) throw new NotFoundException('User not found');
    if (!user.emailVerifiedAt) throw new ForbiddenException('Email verification is required');

    const secret = this.totp.generateSecret();
    const encrypted = this.totp.encryptSecret(secret);
    await this.prisma.totpConfiguration.upsert({
      where: { userId },
      create: { userId, ...encrypted },
      update: { ...encrypted, enabledAt: null },
    });
    await this.prisma.auditEvent.create({
      data: { actorId: userId, action: 'MFA_TOTP_SETUP_STARTED', entityType: 'User', entityId: userId },
    });

    return {
      secret,
      otpauthUri: this.totp.buildOtpAuthUri(user.email, secret),
      enabled: false,
    };
  }

  async confirmMfa(userId: string, code: string) {
    const configuration = await this.prisma.totpConfiguration.findUnique({ where: { userId } });
    if (!configuration) throw new NotFoundException('MFA setup has not been started');
    const secret = this.totp.decryptSecret(configuration);
    if (!this.totp.verify(code, secret)) throw new UnauthorizedException('Invalid MFA code');

    const enabledAt = configuration.enabledAt ?? new Date();
    await this.prisma.$transaction([
      this.prisma.totpConfiguration.update({ where: { userId }, data: { enabledAt } }),
      this.prisma.auditEvent.create({
        data: { actorId: userId, action: 'MFA_TOTP_ENABLED', entityType: 'User', entityId: userId },
      }),
    ]);
    return { enabled: true, enabledAt };
  }

  async disableMfa(userId: string, code: string) {
    const configuration = await this.prisma.totpConfiguration.findUnique({ where: { userId } });
    if (!configuration?.enabledAt) throw new NotFoundException('MFA is not enabled');
    const secret = this.totp.decryptSecret(configuration);
    if (!this.totp.verify(code, secret)) throw new UnauthorizedException('Invalid MFA code');

    await this.prisma.$transaction([
      this.prisma.totpConfiguration.delete({ where: { userId } }),
      this.prisma.authSession.updateMany({ where: { userId, revokedAt: null }, data: { revokedAt: new Date() } }),
      this.prisma.auditEvent.create({
        data: { actorId: userId, action: 'MFA_TOTP_DISABLED', entityType: 'User', entityId: userId },
      }),
    ]);
    return { enabled: false, sessionsRevoked: true };
  }

  async listSessions(userId: string) {
    return this.prisma.authSession.findMany({
      where: { userId },
      select: {
        id: true,
        deviceId: true,
        userAgent: true,
        ipAddress: true,
        createdAt: true,
        updatedAt: true,
        expiresAt: true,
        revokedAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async revokeSession(userId: string, sessionId: string) {
    const session = await this.prisma.authSession.findFirst({ where: { id: sessionId, userId } });
    if (!session) throw new NotFoundException('Session not found');
    if (!session.revokedAt) {
      await this.prisma.$transaction([
        this.prisma.authSession.update({ where: { id: sessionId }, data: { revokedAt: new Date() } }),
        this.prisma.auditEvent.create({
          data: { actorId: userId, action: 'AUTH_SESSION_REVOKED_BY_USER', entityType: 'AuthSession', entityId: sessionId },
        }),
      ]);
    }
    return { revoked: true };
  }

  async revokeOtherSessions(userId: string, currentSessionId?: string) {
    await this.prisma.authSession.updateMany({
      where: { userId, revokedAt: null, id: currentSessionId ? { not: currentSessionId } : undefined },
      data: { revokedAt: new Date() },
    });
    await this.prisma.auditEvent.create({
      data: { actorId: userId, action: 'OTHER_AUTH_SESSIONS_REVOKED', entityType: 'User', entityId: userId },
    });
    return { revoked: true };
  }
}
