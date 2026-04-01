import { Module } from '@nestjs/common';
import { ExperimentsModule } from '../experiments/experiments.module';
import { JobsController } from './jobs.controller';
import { JobsService } from './jobs.service';

@Module({
  imports: [ExperimentsModule],
  controllers: [JobsController],
  providers: [JobsService],
})
export class JobsModule {}
