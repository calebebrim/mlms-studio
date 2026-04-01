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
  ApiExtraModels,
  ApiHeader,
  ApiOperation,
  ApiTags,
  ApiUnprocessableEntityResponse,
  getSchemaPath,
} from '@nestjs/swagger';
import {
  CreateEchoJobRequestSchema,
  CreateExperimentSnapshotJobRequestSchema,
  CreateGeneticAlgorithmJobRequestSchema,
  CreateMlpJobRequestSchema,
  CreatePipelineStubJobRequestSchema,
  CreateRandomForestJobRequestSchema,
  CreateWatchpointsJobRequestSchema,
  GeneticAlgorithmJobPayloadSchema,
  MlpJobPayloadSchema,
  PipelineStubJobPayloadSchema,
  RandomForestJobPayloadSchema,
  WatchpointsJobPayloadSchema,
} from './dto/create-job-api-body.schema';
import { CreateJobDto } from './dto/create-job.dto';
import { JobResponseDto } from './job-response.dto';
import { JobsService } from './jobs.service';

@ApiTags('Jobs')
@ApiExtraModels(
  CreateEchoJobRequestSchema,
  PipelineStubJobPayloadSchema,
  CreatePipelineStubJobRequestSchema,
  GeneticAlgorithmJobPayloadSchema,
  CreateGeneticAlgorithmJobRequestSchema,
  WatchpointsJobPayloadSchema,
  CreateWatchpointsJobRequestSchema,
  MlpJobPayloadSchema,
  CreateMlpJobRequestSchema,
  RandomForestJobPayloadSchema,
  CreateRandomForestJobRequestSchema,
  CreateExperimentSnapshotJobRequestSchema,
)
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
  @ApiBody({
    description:
      'Alinhado a `CreateJobRequest` / discriminador `job_type` em docs/api/openapi-v0.yaml.',
    schema: {
      oneOf: [
        { $ref: getSchemaPath(CreateEchoJobRequestSchema) },
        { $ref: getSchemaPath(CreatePipelineStubJobRequestSchema) },
        { $ref: getSchemaPath(CreateGeneticAlgorithmJobRequestSchema) },
        { $ref: getSchemaPath(CreateWatchpointsJobRequestSchema) },
        { $ref: getSchemaPath(CreateMlpJobRequestSchema) },
        { $ref: getSchemaPath(CreateRandomForestJobRequestSchema) },
        { $ref: getSchemaPath(CreateExperimentSnapshotJobRequestSchema) },
      ],
      discriminator: {
        propertyName: 'job_type',
        mapping: {
          'mlms.echo': getSchemaPath(CreateEchoJobRequestSchema),
          'mlms.pipeline_stub': getSchemaPath(CreatePipelineStubJobRequestSchema),
          'mlms.genetic_algorithm': getSchemaPath(
            CreateGeneticAlgorithmJobRequestSchema,
          ),
          'mlms.watchpoints': getSchemaPath(CreateWatchpointsJobRequestSchema),
          'mlms.mlp': getSchemaPath(CreateMlpJobRequestSchema),
          'mlms.random_forest': getSchemaPath(CreateRandomForestJobRequestSchema),
          'mlms.experiment_snapshot': getSchemaPath(
            CreateExperimentSnapshotJobRequestSchema,
          ),
        },
      },
    },
  })
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
