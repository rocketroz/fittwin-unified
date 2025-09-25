import { Module } from '@nestjs/common';
import { CartService } from './cart.service';
import { OrdersService } from './orders.service';
import { CartController } from './cart.controller';
import { OrdersController } from './orders.controller';

@Module({
  controllers: [CartController, OrdersController],
  providers: [CartService, OrdersService],
  exports: [CartService, OrdersService]
})
export class CommerceModule {}
