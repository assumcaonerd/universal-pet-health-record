import { IsIn, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpsertProfessionalProfileDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(32)
  licenseNumber!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(2)
  licenseState!: string;

  @IsOptional()
  @IsString()
  @MaxLength(160)
  specialty?: string;

  @IsOptional()
  @IsIn(['PENDING', 'VERIFIED', 'REJECTED'])
  verificationStatus?: 'PENDING' | 'VERIFIED' | 'REJECTED';
}
