import { Module } from '@nestjs/common';
import { TryOnService } from './tryon.service';

@Module({
  providers: [TryOnService],
  exports: [TryOnService]
})
export class TryOnModule {}
