import {
  Body,
  Controller,
  Headers,
  HttpCode,
  HttpStatus,
  Post,
} from '@nestjs/common';
import {
  ApiBody,
  ApiCreatedResponse,
  ApiHeader,
  ApiOperation,
  ApiTags,
  ApiUnprocessableEntityResponse,
} from '@nestjs/swagger';
import { CreateJobDto } from './dto/create-job.dto';
import { JobResponseDto } from './job-response.dto';
import { JobsService } from './jobs.service';

@ApiTags('Jobs')
@Controller('jobs')
export class JobsController {
  constructor(private readonly jobs: JobsService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Submeter job',
    description:
      'MVP síncrono: reencaminha a `POST /v1/jobs` do worker e devolve `201` com estado terminal.',
  })
  @ApiHeader({
    name: 'Idempotency-Key',
    required: false,
    description: 'Chave opcional de idempotência (MVP: sem dedupe persistido).',
  })
  @ApiBody({ type: CreateJobDto })
  @ApiCreatedResponse({ type: JobResponseDto })
  @ApiUnprocessableEntityResponse({ description: 'Rejeição de negócio no worker' })
  async create(
    @Body() dto: CreateJobDto,
    @Headers('idempotency-key') idempotencyHeader?: string,
  ): Promise<JobResponseDto> {
    void (idempotencyHeader ?? dto.idempotency_key);
    return this.jobs.createJob(dto);
  }
}
