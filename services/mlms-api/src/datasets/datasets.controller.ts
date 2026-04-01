import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBody,
  ApiConsumes,
  ApiCreatedResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiUnprocessableEntityResponse,
} from '@nestjs/swagger';
import { memoryStorage } from 'multer';
import { DatasetSpectrumPreviewDto } from './dataset-spectrum-preview.dto';
import { DatasetResponseDto } from './dataset-response.dto';
import { DatasetsService } from './datasets.service';
import { CreateDatasetDto } from './dto/create-dataset.dto';
import { ListDatasetsQueryDto } from './dto/list-datasets-query.dto';
import { UpdateDatasetDto } from './dto/update-dataset.dto';
import { UploadDatasetFieldsDto } from './dto/upload-dataset-fields.dto';

@ApiTags('Datasets')
@Controller('datasets')
export class DatasetsController {
  constructor(private readonly datasets: DatasetsService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Criar registo de dataset (metadados + ref ao volume)' })
  @ApiCreatedResponse({ type: DatasetResponseDto })
  @ApiUnprocessableEntityResponse({
    description: 'Validação (class-validator / storage_ref)',
  })
  async create(@Body() dto: CreateDatasetDto): Promise<DatasetResponseDto> {
    return this.datasets.create(dto);
  }

  @Post('upload')
  @HttpCode(HttpStatus.CREATED)
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: 50 * 1024 * 1024 },
    }),
  )
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['file'],
      properties: {
        file: { type: 'string', format: 'binary' },
        name: { type: 'string' },
        description: { type: 'string' },
        tags: { type: 'string', description: 'Separadas por vírgula' },
        metadata: { type: 'string', description: 'JSON object opcional' },
      },
    },
  })
  @ApiOperation({
    summary: 'Carregar ficheiro (multipart) e criar registo no volume',
    description:
      'Grava em `uploads/<uuid>/<nome>` sob `MLMS_DATA_VOLUME_PREFIX` e define `storage_ref`.',
  })
  @ApiCreatedResponse({ type: DatasetResponseDto })
  @ApiUnprocessableEntityResponse()
  async upload(
    @UploadedFile() file: Express.Multer.File,
    @Body() body: UploadDatasetFieldsDto,
  ): Promise<DatasetResponseDto> {
    return this.datasets.createFromUploadedFile(file, body);
  }

  @Get()
  @ApiOperation({ summary: 'Listar datasets (omite eliminados por defeito)' })
  @ApiOkResponse({ type: DatasetResponseDto, isArray: true })
  async list(
    @Query() query: ListDatasetsQueryDto,
  ): Promise<DatasetResponseDto[]> {
    return this.datasets.list(query);
  }

  @Get(':datasetId/spectrum-preview')
  @ApiOperation({
    summary: 'Pré-visualização m/z × intensidade (MVP sintético)',
    description:
      'Curva determinística por dataset até existir ingestão real do ficheiro.',
  })
  @ApiOkResponse({ type: DatasetSpectrumPreviewDto })
  @ApiNotFoundResponse()
  async spectrumPreview(
    @Param('datasetId', ParseUUIDPipe) datasetId: string,
  ): Promise<DatasetSpectrumPreviewDto> {
    return this.datasets.spectrumPreview(datasetId);
  }

  @Get(':datasetId')
  @ApiOperation({
    summary: 'Obter dataset por id (não devolve eliminados logicamente)',
  })
  @ApiOkResponse({ type: DatasetResponseDto })
  @ApiNotFoundResponse()
  async getById(
    @Param('datasetId', ParseUUIDPipe) datasetId: string,
  ): Promise<DatasetResponseDto> {
    return this.datasets.getById(datasetId);
  }

  @Patch(':datasetId')
  @ApiOperation({ summary: 'Atualizar metadados / tags / storage_ref' })
  @ApiOkResponse({ type: DatasetResponseDto })
  @ApiNotFoundResponse()
  @ApiUnprocessableEntityResponse()
  async update(
    @Param('datasetId', ParseUUIDPipe) datasetId: string,
    @Body() dto: UpdateDatasetDto,
  ): Promise<DatasetResponseDto> {
    return this.datasets.update(datasetId, dto);
  }

  @Delete(':datasetId')
  @ApiOperation({ summary: 'Eliminação lógica' })
  @ApiOkResponse({ type: DatasetResponseDto })
  @ApiNotFoundResponse()
  async remove(
    @Param('datasetId', ParseUUIDPipe) datasetId: string,
  ): Promise<DatasetResponseDto> {
    return this.datasets.removeLogical(datasetId);
  }
}
