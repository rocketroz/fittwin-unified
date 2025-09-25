import { Module } from '@nestjs/common';
import { CatalogService } from './catalog.service';
import { BrandController } from './brand.controller';

@Module({
  controllers: [BrandController],
  providers: [CatalogService],
  exports: [CatalogService]
})
export class BrandModule {}
