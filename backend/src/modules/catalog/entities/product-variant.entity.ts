import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { ProductEntity } from './product.entity';

enum ProductVariantStatus {
  ACTIVE = 'active',
  BACKORDER = 'backorder',
  OUT_OF_STOCK = 'out_of_stock'
}

@Entity({ name: 'product_variants' })
export class ProductVariantEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => ProductEntity, (product) => product.variants, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'product_id' })
  product!: ProductEntity;

  @Column({ unique: true })
  sku!: string;

  @Column({ name: 'size_label' })
  sizeLabel!: string;

  @Column({ nullable: true })
  color?: string | null;

  @Column({ name: 'price_cents', type: 'bigint' })
  priceCents!: number;

  @Column({ length: 3 })
  currency!: string;

  @Column()
  inventory!: number;

  @Column({ name: 'fit_metadata', type: 'jsonb', nullable: true })
  fitMetadata?: Record<string, unknown> | null;

  @Column({ type: 'enum', enum: ProductVariantStatus, default: ProductVariantStatus.ACTIVE })
  status!: ProductVariantStatus;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}

export { ProductVariantStatus };
