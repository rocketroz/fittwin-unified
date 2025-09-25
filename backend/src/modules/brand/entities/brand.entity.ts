import {
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { BrandUserEntity } from './brand-user.entity';
import { ProductEntity } from '../../catalog/entities/product.entity';
import { SizeChartEntity } from '../../catalog/entities/size-chart.entity';
import { FitMapEntity } from '../../catalog/entities/fit-map.entity';

export enum BrandOnboardingStatus {
  INVITED = 'invited',
  KYC_PENDING = 'kyc_pending',
  ACTIVE = 'active',
  SUSPENDED = 'suspended'
}

@Entity({ name: 'brands' })
export class BrandEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ unique: true })
  name!: string;

  @Column({ name: 'onboarding_status', type: 'enum', enum: BrandOnboardingStatus, default: BrandOnboardingStatus.INVITED })
  onboardingStatus!: BrandOnboardingStatus;

  @Column({ name: 'primary_contact', type: 'jsonb' })
  primaryContact!: Record<string, unknown>;

  @Column({ type: 'jsonb', nullable: true })
  webhooks?: Record<string, unknown> | null;

  @OneToMany(() => BrandUserEntity, (brandUser) => brandUser.brand)
  users!: BrandUserEntity[];

  @OneToMany(() => ProductEntity, (product) => product.brand)
  products!: ProductEntity[];

  @OneToMany(() => SizeChartEntity, (sizeChart) => sizeChart.brand)
  sizeCharts!: SizeChartEntity[];

  @OneToMany(() => FitMapEntity, (fitMap) => fitMap.brand)
  fitMaps!: FitMapEntity[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
