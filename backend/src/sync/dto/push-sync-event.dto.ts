import { IsInt, IsNotEmpty, IsObject, IsOptional, IsString, IsUUID, MaxLength, Min } from 'class-validator';

export class PushSyncEventDto {
  @IsUUID()
  clientEventId!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  deviceId!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  entityType!: string;

  @IsUUID()
  entityId!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(40)
  operation!: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  version?: number;

  @IsOptional()
  @IsObject()
  payload?: Record<string, unknown>;
}
