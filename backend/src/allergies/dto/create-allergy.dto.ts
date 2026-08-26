import { IsIn, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateAllergyDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(160)
  allergen!: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  reaction?: string;

  @IsOptional()
  @IsIn(['MILD', 'MODERATE', 'SEVERE', 'LIFE_THREATENING'])
  severity?: 'MILD' | 'MODERATE' | 'SEVERE' | 'LIFE_THREATENING';

  @IsOptional()
  @IsString()
  accessToken?: string;
}
