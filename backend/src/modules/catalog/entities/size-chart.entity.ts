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
import { ProductEntity } from './product.entity';

export enum UnitSystem {
  METRIC = 'metric',
  IMPERIAL = 'imperial'
}

@Entity({ name: 'size_charts' })
export class SizeChartEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => BrandEntity, (brand) => brand.sizeCharts, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'brand_id' })
  brand!: BrandEntity;

  @Column({ name: 'garment_type' })
  garmentType!: string;

  @Column({ name: 'measurement_rules', type: 'jsonb' })
  measurementRules!: Record<string, unknown>;

  @Column({ name: 'grading_rules', type: 'jsonb', nullable: true })
  gradingRules?: Record<string, unknown> | null;

  @Column({ name: 'unit_system', type: 'enum', enum: UnitSystem })
  unitSystem!: UnitSystem;

  @OneToMany(() => ProductEntity, (product) => product.sizeChart)
  products!: ProductEntity[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
