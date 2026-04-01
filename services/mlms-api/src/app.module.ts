import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DatasetsModule } from './datasets/datasets.module';
import { ExperimentsModule } from './experiments/experiments.module';
import { HealthModule } from './health/health.module';
import { JobsModule } from './jobs/jobs.module';
import { WorkerClientModule } from './worker/worker-client.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    WorkerClientModule,
    HealthModule,
    JobsModule,
    DatasetsModule,
    ExperimentsModule,
  ],
})
export class AppModule {}
