import { IsInt, IsNotEmpty, IsString, Matches, Max, MaxLength, Min } from 'class-validator';

export class CreateUploadIntentDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  fileName!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  mimeType!: string;

  @IsString()
  @Matches(/^[a-fA-F0-9]{64}$/)
  sha256!: string;

  @IsInt()
  @Min(1)
  @Max(50_000_000)
  sizeBytes!: number;
}
