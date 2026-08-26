import { Module } from '@nestjs/common';
import { AllergiesController } from './allergies.controller';
import { AllergiesService } from './allergies.service';

@Module({
  controllers: [AllergiesController],
  providers: [AllergiesService],
})
export class AllergiesModule {}
