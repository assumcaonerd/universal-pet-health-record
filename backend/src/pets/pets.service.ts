import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePetDto } from './dto/create-pet.dto';
import { UpdatePetDto } from './dto/update-pet.dto';

@Injectable()
export class PetsService {
  constructor(private readonly prisma: PrismaService) {}

  listForOwner(ownerId: string) {
    return this.prisma.pet.findMany({ where: { primaryOwnerId: ownerId }, orderBy: { createdAt: 'desc' } });
  }

  async getForOwner(id: string, ownerId: string) {
    const pet = await this.prisma.pet.findUnique({ where: { id } });
    if (!pet) throw new NotFoundException('Pet not found');
    if (pet.primaryOwnerId !== ownerId) throw new ForbiddenException('You do not have access to this pet');
    return pet;
  }

  async create(ownerId: string, dto: CreatePetDto) {
    const pet = await this.prisma.pet.create({
      data: {
        ...dto,
        birthDate: dto.birthDate ? new Date(dto.birthDate) : undefined,
        primaryOwnerId: ownerId,
      },
    });
    await this.audit(ownerId, 'PET_CREATED', pet.id, { version: pet.version });
    return pet;
  }

  async update(id: string, ownerId: string, dto: UpdatePetDto) {
    const pet = await this.getForOwner(id, ownerId);
    const updated = await this.prisma.pet.update({
      where: { id },
      data: {
        ...dto,
        birthDate: dto.birthDate ? new Date(dto.birthDate) : undefined,
        version: { increment: 1 },
      },
    });
    await this.audit(ownerId, 'PET_UPDATED', id, { previousVersion: pet.version, version: updated.version });
    return updated;
  }

  async remove(id: string, ownerId: string) {
    await this.getForOwner(id, ownerId);
    await this.prisma.pet.delete({ where: { id } });
    await this.audit(ownerId, 'PET_DELETED', id);
    return { deleted: true };
  }

  private audit(actorId: string, action: string, entityId: string, metadata?: Prisma.InputJsonValue) {
    return this.prisma.auditEvent.create({
      data: { actorId, action, entityType: 'Pet', entityId, metadata },
    });
  }
}
