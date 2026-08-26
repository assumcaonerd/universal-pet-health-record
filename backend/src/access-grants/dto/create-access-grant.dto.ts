import { IsIn, IsInt, IsOptional, Max, Min } from 'class-validator';

export class CreateAccessGrantDto {
  @IsOptional()
  @IsIn(['READ', 'WRITE'])
  level?: 'READ' | 'WRITE';

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(60)
  expiresInMinutes?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(20)
  maxUses?: number;
}
