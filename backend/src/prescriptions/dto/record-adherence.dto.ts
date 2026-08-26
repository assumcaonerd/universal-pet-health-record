import { IsDateString, IsIn, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class RecordAdherenceDto {
  @IsDateString()
  scheduledAt!: string;

  @IsOptional()
  @IsDateString()
  administeredAt?: string;

  @IsIn(['TAKEN', 'SKIPPED'])
  status!: 'TAKEN' | 'SKIPPED';

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  note?: string;

  @IsOptional()
  @IsUUID()
  clientEventId?: string;
}
