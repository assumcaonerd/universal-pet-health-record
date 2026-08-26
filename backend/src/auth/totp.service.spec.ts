import { TotpService } from './totp.service';

describe('TotpService', () => {
  const originalKey = process.env.MFA_ENCRYPTION_KEY;
  const service = new TotpService();

  beforeAll(() => {
    process.env.MFA_ENCRYPTION_KEY = Buffer.alloc(32, 7).toString('base64');
  });

  afterAll(() => {
    if (originalKey === undefined) delete process.env.MFA_ENCRYPTION_KEY;
    else process.env.MFA_ENCRYPTION_KEY = originalKey;
  });

  it('encrypts and decrypts TOTP secrets without storing plaintext', () => {
    const encrypted = service.encryptSecret('JBSWY3DPEHPK3PXP');
    expect(encrypted.secretCiphertext).not.toContain('JBSWY3DPEHPK3PXP');
    expect(service.decryptSecret(encrypted)).toBe('JBSWY3DPEHPK3PXP');
  });

  it('matches the RFC 6238 SHA1 six-digit vector', () => {
    const secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';
    expect(service.verify('287082', secret, 59_000)).toBe(true);
    expect(service.verify('000000', secret, 59_000)).toBe(false);
  });
});
