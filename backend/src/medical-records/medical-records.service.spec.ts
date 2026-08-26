import { ForbiddenException } from '@nestjs/common';
import { MedicalRecordsService } from './medical-records.service';

describe('MedicalRecordsService', () => {
  it('rejects clinical writes from an unverified professional', async () => {
    const prisma: any = {
      professionalProfile: { findUnique: jest.fn().mockResolvedValue({ verificationStatus: 'PENDING' }) },
    };
    const service = new MedicalRecordsService(prisma);

    await expect(
      service.create('vet', 'pet', {
        accessToken: 'this-is-a-long-owner-token',
        type: 'CONSULTATION',
        occurredAt: new Date().toISOString(),
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('rejects amendments by a veterinarian who did not author the record', async () => {
    const prisma: any = {
      professionalProfile: { findUnique: jest.fn().mockResolvedValue({ verificationStatus: 'VERIFIED' }) },
      medicalRecord: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'record',
          veterinarianId: 'original-vet',
          currentVersion: 1,
          diagnosis: null,
          treatment: null,
          notes: null,
        }),
      },
    };
    const service = new MedicalRecordsService(prisma);

    await expect(service.amend('other-vet', 'record', { reason: 'Correction' })).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });
});
