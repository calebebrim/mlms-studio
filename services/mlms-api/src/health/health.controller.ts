import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  @Get()
  @ApiOperation({ summary: 'Health do API Node (BFF)' })
  getHealth() {
    return {
      status: 'ok',
      service: 'mlms-api',
      version: '0.1.0',
    };
  }
}
