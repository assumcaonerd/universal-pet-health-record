import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { createCipheriv, createDecipheriv, createHash, createHmac, randomBytes, timingSafeEqual } from 'crypto';

@Injectable()
export class TotpService {
  private readonly alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  private encryptionKey() {
    const configured = process.env.MFA_ENCRYPTION_KEY;
    if (configured) {
      const key = Buffer.from(configured, 'base64');
      if (key.length !== 32) throw new InternalServerErrorException('MFA_ENCRYPTION_KEY must decode to 32 bytes');
      return key;
    }
    if (process.env.NODE_ENV === 'production') {
      throw new InternalServerErrorException('MFA_ENCRYPTION_KEY is not configured');
    }
    return createHash('sha256').update(process.env.JWT_SECRET ?? 'development-only-mfa-key').digest();
  }

  generateSecret() {
    return this.base32Encode(randomBytes(20));
  }

  buildOtpAuthUri(email: string, secret: string) {
    const issuer = process.env.MFA_ISSUER ?? 'Universal Pet Health Record';
    const label = `${issuer}:${email}`;
    return `otpauth://totp/${encodeURIComponent(label)}?secret=${secret}&issuer=${encodeURIComponent(issuer)}&algorithm=SHA1&digits=6&period=30`;
  }

  encryptSecret(secret: string) {
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', this.encryptionKey(), iv);
    const ciphertext = Buffer.concat([cipher.update(secret, 'utf8'), cipher.final()]);
    const authTag = cipher.getAuthTag();
    return {
      secretCiphertext: ciphertext.toString('base64'),
      iv: iv.toString('base64'),
      authTag: authTag.toString('base64'),
    };
  }

  decryptSecret(input: { secretCiphertext: string; iv: string; authTag: string }) {
    const decipher = createDecipheriv('aes-256-gcm', this.encryptionKey(), Buffer.from(input.iv, 'base64'));
    decipher.setAuthTag(Buffer.from(input.authTag, 'base64'));
    return Buffer.concat([
      decipher.update(Buffer.from(input.secretCiphertext, 'base64')),
      decipher.final(),
    ]).toString('utf8');
  }

  verify(code: string, secret: string, now = Date.now()) {
    if (!/^\d{6}$/.test(code)) return false;
    const counter = Math.floor(now / 1000 / 30);
    for (let offset = -1; offset <= 1; offset += 1) {
      const expected = this.codeForCounter(secret, counter + offset);
      const left = Buffer.from(code);
      const right = Buffer.from(expected);
      if (left.length === right.length && timingSafeEqual(left, right)) return true;
    }
    return false;
  }

  private codeForCounter(secret: string, counter: number) {
    const message = Buffer.alloc(8);
    message.writeBigUInt64BE(BigInt(counter));
    const digest = createHmac('sha1', this.base32Decode(secret)).update(message).digest();
    const offset = digest[digest.length - 1] & 0x0f;
    const binary =
      ((digest[offset] & 0x7f) << 24) |
      ((digest[offset + 1] & 0xff) << 16) |
      ((digest[offset + 2] & 0xff) << 8) |
      (digest[offset + 3] & 0xff);
    return String(binary % 1_000_000).padStart(6, '0');
  }

  private base32Encode(buffer: Buffer) {
    let bits = 0;
    let value = 0;
    let output = '';
    for (const byte of buffer) {
      value = (value << 8) | byte;
      bits += 8;
      while (bits >= 5) {
        output += this.alphabet[(value >>> (bits - 5)) & 31];
        bits -= 5;
      }
    }
    if (bits > 0) output += this.alphabet[(value << (5 - bits)) & 31];
    return output;
  }

  private base32Decode(input: string) {
    let bits = 0;
    let value = 0;
    const bytes: number[] = [];
    for (const char of input.replace(/=+$/g, '').toUpperCase()) {
      const index = this.alphabet.indexOf(char);
      if (index < 0) throw new Error('Invalid base32 secret');
      value = (value << 5) | index;
      bits += 5;
      if (bits >= 8) {
        bytes.push((value >>> (bits - 8)) & 0xff);
        bits -= 8;
      }
    }
    return Buffer.from(bytes);
  }
}
