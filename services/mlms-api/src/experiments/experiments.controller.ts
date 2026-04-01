import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import {
  ApiCreatedResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { AppendPipelineRevisionDto } from './dto/append-pipeline-revision.dto';
import { CreateExperimentDto } from './dto/create-experiment.dto';
import { ExperimentResponseDto } from './experiment-response.dto';
import { ExperimentsService } from './experiments.service';
import { PipelineRevisionDetailDto } from './pipeline-revision-response.dto';

@ApiTags('Experiments')
@Controller('experiments')
export class ExperimentsController {
  constructor(private readonly experiments: ExperimentsService) {}

  @Post()
  @ApiOperation({ summary: 'Criar experimento (revisões de pipeline em append-only)' })
  @ApiCreatedResponse({ type: ExperimentResponseDto })
  async create(@Body() dto: CreateExperimentDto): Promise<ExperimentResponseDto> {
    return this.experiments.create(dto);
  }

  @Get(':experimentId')
  @ApiOperation({ summary: 'Obter experimento e sumários das revisões' })
  @ApiOkResponse({ type: ExperimentResponseDto })
  async getOne(
    @Param('experimentId') experimentId: string,
  ): Promise<ExperimentResponseDto> {
    return this.experiments.getById(experimentId);
  }

  @Post(':experimentId/revisions')
  @ApiOperation({ summary: 'Anexar nova revisão imutável de PipelineSpec (+ estado opcional)' })
  @ApiCreatedResponse({ type: PipelineRevisionDetailDto })
  async appendRevision(
    @Param('experimentId') experimentId: string,
    @Body() dto: AppendPipelineRevisionDto,
  ): Promise<PipelineRevisionDetailDto> {
    return this.experiments.appendRevision(experimentId, dto);
  }

  @Get(':experimentId/revisions/:revisionId')
  @ApiOperation({ summary: 'Ler uma revisão congelada (sem mutação)' })
  @ApiOkResponse({ type: PipelineRevisionDetailDto })
  async getRevision(
    @Param('experimentId') experimentId: string,
    @Param('revisionId') revisionId: string,
  ): Promise<PipelineRevisionDetailDto> {
    return this.experiments.getRevision(experimentId, revisionId);
  }
}
