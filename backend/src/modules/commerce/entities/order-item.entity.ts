import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { OrderEntity } from './order.entity';
import { ProductEntity } from '../../catalog/entities/product.entity';
import { ProductVariantEntity } from '../../catalog/entities/product-variant.entity';

@Entity({ name: 'order_items' })
export class OrderItemEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => OrderEntity, (order) => order.items, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'order_id' })
  order!: OrderEntity;

  @ManyToOne(() => ProductEntity, { nullable: true })
  @JoinColumn({ name: 'product_id' })
  product?: ProductEntity | null;

  @ManyToOne(() => ProductVariantEntity, { nullable: true })
  @JoinColumn({ name: 'variant_id' })
  variant?: ProductVariantEntity | null;

  @Column()
  sku!: string;

  @Column({ name: 'size_label' })
  sizeLabel!: string;

  @Column({ type: 'smallint' })
  qty!: number;

  @Column({ name: 'unit_price_cents', type: 'bigint' })
  unitPriceCents!: number;

  @Column({ length: 3 })
  currency!: string;

  @Column({ name: 'fit_summary', type: 'jsonb', nullable: true })
  fitSummary?: Record<string, unknown> | null;
}
