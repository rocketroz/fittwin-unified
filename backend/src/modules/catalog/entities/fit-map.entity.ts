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

@Entity({ name: 'fit_maps' })
export class FitMapEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => BrandEntity, (brand) => brand.fitMaps, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'brand_id' })
  brand!: BrandEntity;

  @Column({ name: 'garment_type' })
  garmentType!: string;

  @Column({ name: 'rule_set', type: 'jsonb' })
  ruleSet!: Record<string, unknown>;

  @Column({ name: 'confidence_model', type: 'jsonb', nullable: true })
  confidenceModel?: Record<string, unknown> | null;

  @OneToMany(() => ProductEntity, (product) => product.fitMap)
  products!: ProductEntity[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
