import { IsString, Matches, MinLength } from 'class-validator';

export class PasswordResetConfirmDto {
  @IsString()
  @MinLength(32)
  token!: string;

  @IsString()
  @MinLength(12)
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{12,}$/)
  newPassword!: string;
}
