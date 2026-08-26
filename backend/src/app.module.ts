import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AccessGrantsModule } from './access-grants/access-grants.module';
import { AccountModule } from './account/account.module';
import { AllergiesModule } from './allergies/allergies.module';
import { AuthModule } from './auth/auth.module';
import { ClinicalAttachmentsModule } from './clinical-attachments/clinical-attachments.module';
import { EmailModule } from './email/email.module';
import { HealthModule } from './health/health.module';
import { MedicalRecordsModule } from './medical-records/medical-records.module';
import { OrganizationsModule } from './organizations/organizations.module';
import { PetsModule } from './pets/pets.module';
import { PrescriptionsModule } from './prescriptions/prescriptions.module';
import { PrismaModule } from './prisma/prisma.module';
import { ProfessionalsModule } from './professionals/professionals.module';
import { SyncModule } from './sync/sync.module';
import { UsersModule } from './users/users.module';
import { VaccinationsModule } from './vaccinations/vaccinations.module';

@Module({
  imports: [
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 120 }]),
    PrismaModule,
    EmailModule,
    HealthModule,
    UsersModule,
    AuthModule,
    AccountModule,
    PetsModule,
    OrganizationsModule,
    ProfessionalsModule,
    AccessGrantsModule,
    MedicalRecordsModule,
    VaccinationsModule,
    PrescriptionsModule,
    AllergiesModule,
    ClinicalAttachmentsModule,
    SyncModule,
  ],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
