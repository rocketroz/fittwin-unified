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

enum RewardLedgerStatus {
  PENDING_HOLD = 'pending_hold',
  PAYABLE = 'payable',
  PAID = 'paid',
  CANCELLED = 'cancelled'
}

@Entity({ name: 'reward_ledger_entries' })
export class RewardLedgerEntryEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => ReferralEntity, (referral) => referral.rewardEntries, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'rid' })
  referral!: ReferralEntity;

  @ManyToOne(() => OrderEntity, (order) => order.id, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'order_id' })
  order!: OrderEntity;

  @Column({ name: 'amount_cents', type: 'bigint' })
  amountCents!: number;

  @Column({ length: 3 })
  currency!: string;

  @Column({ type: 'enum', enum: RewardLedgerStatus, default: RewardLedgerStatus.PENDING_HOLD })
  status!: RewardLedgerStatus;

  @Column({ name: 'hold_until', type: 'date', nullable: true })
  holdUntil?: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}

export { RewardLedgerStatus };
