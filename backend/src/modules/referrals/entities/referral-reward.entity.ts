import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { ReferralEntity } from './referral.entity';
import { OrderEntity } from '../../commerce/entities/order.entity';
import { UserProfileEntity } from '../../profiles/entities/user-profile.entity';

export enum ReferralRewardStatus {
  PENDING = 'pending',
  ISSUED = 'issued',
  CANCELLED = 'cancelled',
}

export enum ReferralRewardType {
  CREDIT = 'credit',
  DISCOUNT = 'discount',
  CASH = 'cash',
  POINTS = 'points',
}

@Entity({ name: 'referral_rewards' })
export class ReferralRewardEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => ReferralEntity, (referral) => referral.rewards, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'referral_id' })
  referral!: ReferralEntity;

  @ManyToOne(() => UserProfileEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'referrer_id' })
  referrer!: UserProfileEntity;

  @ManyToOne(() => UserProfileEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'referee_id' })
  referee!: UserProfileEntity;

  @ManyToOne(() => OrderEntity, (order) => order.rewards, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'order_id' })
  order!: OrderEntity;

  @Column({ name: 'reward_type', type: 'enum', enum: ReferralRewardType })
  rewardType!: ReferralRewardType;

  @Column({ name: 'amount_cents', type: 'int' })
  amountCents!: number;

  @Column({ default: 'USD' })
  currency!: string;

  @Column({ type: 'enum', enum: ReferralRewardStatus, default: ReferralRewardStatus.PENDING })
  status!: ReferralRewardStatus;

  @Column({ name: 'issued_at', type: 'timestamptz', nullable: true })
  issuedAt?: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
