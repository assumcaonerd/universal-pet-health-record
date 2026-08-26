import { IsIn, IsUUID } from 'class-validator';

export class AddMemberDto {
  @IsUUID()
  userId!: string;

  @IsIn(['ADMIN', 'VETERINARIAN', 'STAFF'])
  role!: 'ADMIN' | 'VETERINARIAN' | 'STAFF';
}
