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
import { OrderItemEntity } from './order-item.entity';
import { ReferralEntity } from '../../referrals/entities/referral.entity';
import { ReferralRewardEntity } from '../../referrals/entities/referral-reward.entity';
import { AddressEntity } from '../../common/entities/address.entity';
import { PaymentMethodEntity } from './payment-method.entity';

export enum OrderStatus {
  CREATED = 'created',
  PAID = 'paid',
  SENT_TO_BRAND = 'sent_to_brand',
  FULFILLED = 'fulfilled',
  DELIVERED = 'delivered',
  RETURN_REQUESTED = 'return_requested',
  CLOSED = 'closed',
  CANCELLED = 'cancelled',
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

  @ManyToOne(() => AddressEntity, { nullable: true })
  @JoinColumn({ name: 'shipping_address_id' })
  shippingAddress?: AddressEntity | null;

  @ManyToOne(() => AddressEntity, { nullable: true })
  @JoinColumn({ name: 'billing_address_id' })
  billingAddress?: AddressEntity | null;

  @ManyToOne(() => PaymentMethodEntity, { nullable: true })
  @JoinColumn({ name: 'payment_method_id' })
  paymentMethod?: PaymentMethodEntity | null;

  @Column({ name: 'payment_intent_ref' })
  paymentIntentRef!: string;

  @Column({ name: 'subtotal_cents', type: 'int' })
  subtotalCents!: number;

  @Column({ name: 'shipping_cents', type: 'int' })
  shippingCents!: number;

  @Column({ name: 'tax_cents', type: 'int' })
  taxCents!: number;

  @Column({ name: 'total_cents', type: 'int' })
  totalCents!: number;

  @Column({ default: 'USD' })
  currency!: string;

  @Column({ name: 'tracking_number', nullable: true })
  trackingNumber?: string | null;

  @ManyToOne(() => ReferralEntity, (referral) => referral.orders, {
    nullable: true,
    onDelete: 'SET NULL',
  })
  @JoinColumn({ name: 'referral_id' })
  referral?: ReferralEntity | null;

  @OneToMany(() => OrderItemEntity, (item) => item.order, { cascade: true })
  items!: OrderItemEntity[];

  @OneToMany(() => ReferralRewardEntity, (reward) => reward.order)
  rewards!: ReferralRewardEntity[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
