import { IsDateString, IsNotEmpty, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class CreateVaccinationDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(160)
  vaccineName!: string;

  @IsOptional()
  @IsString()
  @MaxLength(160)
  manufacturer?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  batchNumber?: string;

  @IsDateString()
  dateAdministered!: string;

  @IsOptional()
  @IsDateString()
  nextDueDate?: string;

  @IsOptional()
  @IsUUID()
  organizationId?: string;

  @IsString()
  @IsNotEmpty()
  accessToken!: string;
}
