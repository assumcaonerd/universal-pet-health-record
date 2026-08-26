import { Body, Controller, Param, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AddMemberDto } from './dto/add-member.dto';
import { OrganizationAccessService } from './organization-access.service';

@Controller('organizations/:organizationId/members')
@UseGuards(JwtAuthGuard)
export class OrganizationMembersController {
  constructor(private readonly access: OrganizationAccessService) {}

  @Post()
  addMember(
    @Req() req: any,
    @Param('organizationId') organizationId: string,
    @Body() dto: AddMemberDto,
  ) {
    return this.access.addMember(req.user.sub, organizationId, dto);
  }
}
