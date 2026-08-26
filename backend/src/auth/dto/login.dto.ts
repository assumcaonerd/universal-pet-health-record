import { IsEmail, IsOptional, IsString, Matches, MinLength } from 'class-validator';

export class LoginDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(8)
  password!: string;

  @IsOptional()
  @Matches(/^\d{6}$/)
  mfaCode?: string;

  @IsOptional()
  @Matches(/^[A-Z0-9]{4}-[A-Z0-9]{4}$/)
  recoveryCode?: string;
}
