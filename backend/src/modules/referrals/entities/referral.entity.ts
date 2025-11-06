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
import { UserProfileEntity } from '../../profiles/entities/user-profile.entity';
import { ProductEntity } from '../../catalog/entities/product.entity';
import { ReferralEventEntity } from './referral-event.entity';
import { OrderEntity } from '../../commerce/entities/order.entity';
import { ReferralRewardEntity } from './referral-reward.entity';

export enum ReferralStatus {
  ACTIVE = 'active',
  EXPIRED = 'expired',
  FRAUD_FLAGGED = 'fraud_flagged',
}

@Entity({ name: 'referrals' })
export class ReferralEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ unique: true })
  rid!: string;

  @ManyToOne(() => UserProfileEntity, (user) => user.referrals, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'referrer_id' })
  referrer!: UserProfileEntity;

  @ManyToOne(() => ProductEntity, { nullable: true })
  @JoinColumn({ name: 'product_id' })
  product?: ProductEntity | null;

  @Column({ nullable: true })
  campaign?: string | null;

  @Column({ type: 'enum', enum: ReferralStatus, default: ReferralStatus.ACTIVE })
  status!: ReferralStatus;

  @Column({ name: 'expires_at', type: 'timestamptz', nullable: true })
  expiresAt?: Date | null;

  @OneToMany(() => ReferralEventEntity, (event) => event.referral)
  events!: ReferralEventEntity[];

  @OneToMany(() => OrderEntity, (order) => order.referral)
  orders!: OrderEntity[];

  @OneToMany(() => ReferralRewardEntity, (reward) => reward.referral)
  rewards!: ReferralRewardEntity[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
