import { BadRequestException, Body, Controller, Get, Post, Query, Req, UseGuards } from '@nestjs/common';
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
  pull(
    @Req() req: any,
    @Query('cursor') cursor?: string,
    @Query('limit') limitRaw?: string,
    @Query('after') after?: string,
  ) {
    const parsedLimit = limitRaw == null ? 100 : Number(limitRaw);
    if (!Number.isInteger(parsedLimit) || parsedLimit < 1 || parsedLimit > 200) {
      throw new BadRequestException('limit must be an integer between 1 and 200');
    }
    const afterDate = after ? new Date(after) : undefined;
    if (afterDate && Number.isNaN(afterDate.getTime())) throw new BadRequestException('after must be a valid ISO date');
    return this.sync.pullPage(req.user.sub, { cursor, limit: parsedLimit, after: afterDate });
  }
}
