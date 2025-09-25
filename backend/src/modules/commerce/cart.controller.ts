import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, Patch, Post } from '@nestjs/common';
import { CartService } from './cart.service';

@Controller()
export class CartController {
  constructor(private readonly cartService: CartService) {}

  @Post('cart/items')
  @HttpCode(HttpStatus.CREATED)
  addItem(@Body() payload: Record<string, unknown>) {
    return this.cartService.addItem(payload);
  }

  @Patch('cart/items/:itemId')
  updateItem(@Param('itemId') itemId: string, @Body() payload: Record<string, unknown>) {
    return this.cartService.updateItem(itemId, payload);
  }

  @Delete('cart/items/:itemId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async removeItem(@Param('itemId') itemId: string) {
    await this.cartService.removeItem(itemId);
    return;
  }

  @Get('cart')
  getCart() {
    return this.cartService.getCart();
  }

  @Post('checkout')
  @HttpCode(HttpStatus.CREATED)
  checkout(@Body() payload: Record<string, unknown>) {
    return this.cartService.checkout(payload);
  }

  @Post('checkout/confirm')
  @HttpCode(HttpStatus.NO_CONTENT)
  confirmCheckout(@Body() _payload: Record<string, unknown>) {
    return;
  }
}
