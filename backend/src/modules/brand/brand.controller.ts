import { Body, Controller, Get, HttpCode, HttpStatus, Param, Post } from '@nestjs/common';
import { CatalogService } from './catalog.service';

@Controller()
export class BrandController {
  constructor(private readonly catalogService: CatalogService) {}

  @Post('brand/catalog/upload')
  @HttpCode(HttpStatus.ACCEPTED)
  uploadCatalog(@Body() payload: Record<string, unknown>) {
    return this.catalogService.uploadCatalog(payload);
  }

  @Get('brand/catalog/upload/:ingestId')
  getCatalogStatus(@Param('ingestId') ingestId: string) {
    return this.catalogService.getIngestStatus(ingestId);
  }

  @Post('brand/catalog/products')
  @HttpCode(HttpStatus.CREATED)
  upsertProducts(@Body() payload: Record<string, unknown>) {
    return this.catalogService.upsertProduct(payload);
  }

  @Post('brand/sizecharts')
  @HttpCode(HttpStatus.CREATED)
  createSizeChart(@Body() payload: Record<string, unknown>) {
    return this.catalogService.createSizeChart(payload);
  }

  @Post('brand/fitmaps')
  @HttpCode(HttpStatus.CREATED)
  createFitMap(@Body() payload: Record<string, unknown>) {
    return this.catalogService.createFitMap(payload);
  }

  @Post('brand/assets/3d')
  @HttpCode(HttpStatus.ACCEPTED)
  uploadAssets(@Body() payload: Record<string, unknown>) {
    // Asset processing is asynchronous; acknowledge receipt.
    return {
      assetId: `asset-${Date.now()}`,
      status: 'processing',
      metadata: payload
    };
  }
}
