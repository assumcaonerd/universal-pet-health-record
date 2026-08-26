import { IsDateString, IsNotEmpty, IsOptional, IsString, IsUUID, MaxLength, MinLength } from 'class-validator';

export class CreateMedicalRecordDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(20)
  accessToken!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  type!: string;

  @IsOptional()
  @IsString()
  @MaxLength(4000)
  diagnosis?: string;

  @IsOptional()
  @IsString()
  @MaxLength(4000)
  treatment?: string;

  @IsOptional()
  @IsString()
  @MaxLength(8000)
  notes?: string;

  @IsDateString()
  occurredAt!: string;

  @IsOptional()
  @IsDateString()
  followUpAt?: string;

  @IsOptional()
  @IsUUID()
  organizationId?: string;
}
