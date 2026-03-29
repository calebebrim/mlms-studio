import { Global, Module } from '@nestjs/common';
import { WorkerClientService } from './worker-client.service';

@Global()
@Module({
  providers: [WorkerClientService],
  exports: [WorkerClientService],
})
export class WorkerClientModule {}
