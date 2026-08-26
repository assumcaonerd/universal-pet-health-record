import { Body, Controller, Get, Param, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { VerifiedEmailGuard } from '../auth/verified-email.guard';
import { CreateOrganizationDto } from './dto/create-organization.dto';
import { OrganizationsService } from './organizations.service';

@Controller('organizations')
@UseGuards(JwtAuthGuard)
export class OrganizationsController {
  constructor(private readonly organizations: OrganizationsService) {}

  @Post()
  @UseGuards(VerifiedEmailGuard)
  create(@Req() req: any, @Body() dto: CreateOrganizationDto) {
    return this.organizations.create(req.user.sub, dto);
  }

  @Get()
  list(@Req() req: any) {
    return this.organizations.listForUser(req.user.sub);
  }

  @Get(':id')
  get(@Req() req: any, @Param('id') id: string) {
    return this.organizations.getForUser(req.user.sub, id);
  }
}
