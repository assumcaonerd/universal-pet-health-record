import { Body, Controller, Get, Post, Query, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PushSyncEventDto } from './dto/push-sync-event.dto';
import { SyncService } from './sync.service';

@Controller('sync')
@UseGuards(JwtAuthGuard)
export class SyncController {
  constructor(private readonly sync: SyncService) {}

  @Post('push')
  push(@Req() req: any, @Body() dto: PushSyncEventDto) {
    return this.sync.push(req.user.sub, dto);
  }

  @Get('pull')
  pull(@Req() req: any, @Query('after') after?: string) {
    return this.sync.pull(req.user.sub, after ? new Date(after) : undefined);
  }
}
