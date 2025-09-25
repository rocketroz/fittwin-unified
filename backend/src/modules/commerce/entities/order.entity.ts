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
import { AddressEntity } from '../../common/entities/address.entity';
import { OrderItemEntity } from './order-item.entity';
import { ReferralEntity } from '../../referrals/entities/referral.entity';
import { RewardLedgerEntryEntity } from '../../referrals/entities/reward-ledger-entry.entity';

export enum OrderStatus {
  CREATED = 'created',
  PAID = 'paid',
  SENT_TO_BRAND = 'sent_to_brand',
  FULFILLED = 'fulfilled',
  DELIVERED = 'delivered',
  RETURN_REQUESTED = 'return_requested',
  CLOSED = 'closed'
}

@Entity({ name: 'orders' })
export class OrderEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => UserProfileEntity, (user) => user.orders, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: UserProfileEntity;

  @Column({ type: 'enum', enum: OrderStatus, default: OrderStatus.CREATED })
  status!: OrderStatus;

  @Column({ type: 'jsonb' })
  totals!: Record<string, unknown>;

  @ManyToOne(() => AddressEntity, { nullable: true })
  @JoinColumn({ name: 'shipping_address_id' })
  shippingAddress?: AddressEntity | null;

  @ManyToOne(() => AddressEntity, { nullable: true })
  @JoinColumn({ name: 'billing_address_id' })
  billingAddress?: AddressEntity | null;

  @Column({ name: 'payment_intent_ref' })
  paymentIntentRef!: string;

  @Column({ name: 'psp_token_id' })
  pspTokenId!: string;

  @ManyToOne(() => ReferralEntity, (referral) => referral.orders, { nullable: true })
  @JoinColumn({ name: 'rid' })
  referral?: ReferralEntity | null;

  @Column({ type: 'jsonb', nullable: true })
  notifications?: Record<string, unknown> | null;

  @OneToMany(() => OrderItemEntity, (item) => item.order, { cascade: true })
  items!: OrderItemEntity[];

  @OneToMany(() => RewardLedgerEntryEntity, (entry) => entry.order)
  rewardEntries!: RewardLedgerEntryEntity[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
