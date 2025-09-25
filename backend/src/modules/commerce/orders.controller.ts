import { Body, Controller, Get, HttpCode, HttpStatus, Param, Post, Query } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { OrderStatus } from '../../lib/persistence/in-memory-store';

@Controller()
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Get('orders')
  listOrders(
    @Query('status') status?: OrderStatus,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string
  ) {
    return this.ordersService.listOrders({
      status,
      page: page ? Number(page) : undefined,
      pageSize: pageSize ? Number(pageSize) : undefined
    });
  }

  @Get('orders/:orderId')
  getOrder(@Param('orderId') orderId: string) {
    return this.ordersService.getOrder(orderId);
  }

  @Post('orders/:orderId/return-request')
  @HttpCode(HttpStatus.CREATED)
  createReturnRequest(@Param('orderId') orderId: string, @Body() _payload: Record<string, unknown>) {
    // In this MVP we simply acknowledge the request and log via analytics.
    this.ordersService.handleWebhook({ eventType: 'orders.return_requested', orderId });
    return { status: 'pending_review' };
  }
}
