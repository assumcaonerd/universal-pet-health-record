import { Body, Controller, Delete, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard, AuthenticatedRequest } from '../auth/jwt-auth.guard';
import { CreatePetDto } from './dto/create-pet.dto';
import { UpdatePetDto } from './dto/update-pet.dto';
import { PetsService } from './pets.service';

@Controller('pets')
@UseGuards(JwtAuthGuard)
export class PetsController {
  constructor(private readonly pets: PetsService) {}

  @Get()
  list(@Req() req: AuthenticatedRequest) {
    return this.pets.listForOwner(req.user!.id);
  }

  @Get(':id')
  get(@Param('id') id: string, @Req() req: AuthenticatedRequest) {
    return this.pets.getForOwner(id, req.user!.id);
  }

  @Post()
  create(@Body() dto: CreatePetDto, @Req() req: AuthenticatedRequest) {
    return this.pets.create(req.user!.id, dto);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdatePetDto, @Req() req: AuthenticatedRequest) {
    return this.pets.update(id, req.user!.id, dto);
  }

  @Delete(':id')
  remove(@Param('id') id: string, @Req() req: AuthenticatedRequest) {
    return this.pets.remove(id, req.user!.id);
  }
}
