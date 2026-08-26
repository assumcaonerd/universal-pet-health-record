import { Module } from '@nestjs/common';
import { AccessGrantsModule } from './access-grants/access-grants.module';
import { AuthModule } from './auth/auth.module';
import { HealthModule } from './health/health.module';
import { MedicalRecordsModule } from './medical-records/medical-records.module';
import { OrganizationsModule } from './organizations/organizations.module';
import { PetsModule } from './pets/pets.module';
import { PrescriptionsModule } from './prescriptions/prescriptions.module';
import { PrismaModule } from './prisma/prisma.module';
import { ProfessionalsModule } from './professionals/professionals.module';
import { UsersModule } from './users/users.module';
import { VaccinationsModule } from './vaccinations/vaccinations.module';

@Module({
  imports: [
    PrismaModule,
    HealthModule,
    UsersModule,
    AuthModule,
    PetsModule,
    OrganizationsModule,
    ProfessionalsModule,
    AccessGrantsModule,
    MedicalRecordsModule,
    VaccinationsModule,
    PrescriptionsModule,
  ],
})
export class AppModule {}
