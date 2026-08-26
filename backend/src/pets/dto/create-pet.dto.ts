import { PetSpecies } from '@prisma/client';
import { IsDateString, IsEnum, IsOptional, IsString, MinLength } from 'class-validator';

export class CreatePetDto {
  @IsString()
  @MinLength(1)
  name!: string;

  @IsEnum(PetSpecies)
  species!: PetSpecies;

  @IsOptional()
  @IsString()
  breed?: string;

  @IsOptional()
  @IsDateString()
  birthDate?: string;

  @IsOptional()
  @IsString()
  microchip?: string;
}
