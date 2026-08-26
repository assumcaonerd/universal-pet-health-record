import { Controller, Get } from '@nestjs/common';

@Controller('health')
export class HealthController {
  @Get()
  check() {
    return { status: 'ok', service: 'universal-pet-health-record', timestamp: new Date().toISOString() };
  }
}
