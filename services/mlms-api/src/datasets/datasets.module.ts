import { Module } from '@nestjs/common';
import { DatasetsController } from './datasets.controller';
import { DatasetsRepository } from './datasets.repository';
import { DatasetsService } from './datasets.service';
import { VolumePathService } from './volume-path.service';

@Module({
  controllers: [DatasetsController],
  providers: [DatasetsService, DatasetsRepository, VolumePathService],
  exports: [DatasetsService],
})
export class DatasetsModule {}
