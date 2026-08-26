import { Module } from '@nestjs/common';
import { OrganizationAccessService } from './organization-access.service';
import { OrganizationMembersController } from './organization-members.controller';
import { OrganizationsController } from './organizations.controller';
import { OrganizationsService } from './organizations.service';

@Module({
  controllers: [OrganizationsController, OrganizationMembersController],
  providers: [OrganizationsService, OrganizationAccessService],
})
export class OrganizationsModule {}
