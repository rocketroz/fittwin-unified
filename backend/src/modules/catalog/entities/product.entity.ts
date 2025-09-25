import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { BrandEntity } from '../../brand/entities/brand.entity';
import { SizeChartEntity } from './size-chart.entity';
import { FitMapEntity } from './fit-map.entity';
import { ProductVariantEntity } from './product-variant.entity';

export enum ProductStatus {
  DRAFT = 'draft',
  ACTIVE = 'active',
  ARCHIVED = 'archived'
}

@Entity({ name: 'products' })
export class ProductEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => BrandEntity, (brand) => brand.products, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'brand_id' })
  brand!: BrandEntity;

  @Column()
  title!: string;

  @Column({ type: 'text' })
  description!: string;

  @Column()
  category!: string;

  @Column({ type: 'jsonb' })
  assets!: Record<string, unknown>;

  @ManyToOne(() => SizeChartEntity, (sizeChart) => sizeChart.products, { nullable: true })
  @JoinColumn({ name: 'size_chart_id' })
  sizeChart?: SizeChartEntity | null;

  @ManyToOne(() => FitMapEntity, (fitMap) => fitMap.products, { nullable: true })
  @JoinColumn({ name: 'fit_map_id' })
  fitMap?: FitMapEntity | null;

  @Column({ type: 'enum', enum: ProductStatus, default: ProductStatus.DRAFT })
  status!: ProductStatus;

  @OneToMany(() => ProductVariantEntity, (variant) => variant.product)
  variants!: ProductVariantEntity[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
