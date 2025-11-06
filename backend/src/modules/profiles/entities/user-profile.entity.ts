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
import { AvatarEntity } from './avatar.entity';
import { PaymentMethodEntity } from '../../commerce/entities/payment-method.entity';
import { AddressEntity } from '../../common/entities/address.entity';
import { OrderEntity } from '../../commerce/entities/order.entity';
import { ReferralEntity } from '../../referrals/entities/referral.entity';
import { CartEntity } from '../../commerce/entities/cart.entity';

@Entity({ name: 'user_profiles' })
export class UserProfileEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ unique: true })
  email!: string;

  @Column({ name: 'password_hash' })
  passwordHash!: string;

  @Column({ name: 'email_verified_at', type: 'timestamptz', nullable: true })
  emailVerifiedAt?: Date | null;

  @Column({ unique: true })
  username!: string;

  @Column({ nullable: true })
  name?: string | null;

  @Column({ nullable: true })
  phone?: string | null;

  @Column({ type: 'jsonb', nullable: true })
  location?: Record<string, unknown> | null;

  @Column({ type: 'jsonb', nullable: true })
  appearance?: Record<string, unknown> | null;

  @Column({ name: 'style_preferences', type: 'jsonb', nullable: true })
  stylePreferences?: Record<string, unknown> | null;

  @Column({ name: 'body_metrics', type: 'jsonb' })
  bodyMetrics!: Record<string, unknown>;

  @ManyToOne(() => PaymentMethodEntity, (payment) => payment.defaultProfiles, { nullable: true })
  @JoinColumn({ name: 'default_payment_method_id' })
  defaultPaymentMethod?: PaymentMethodEntity | null;

  @ManyToOne(() => AddressEntity, { nullable: true })
  @JoinColumn({ name: 'billing_address_id' })
  billingAddress?: AddressEntity | null;

  @Column({ type: 'jsonb', nullable: true })
  consents?: Record<string, unknown> | null;

  @OneToMany(() => AvatarEntity, (avatar) => avatar.user)
  avatars!: AvatarEntity[];

  @OneToMany(() => AddressEntity, (address) => address.user)
  addresses!: AddressEntity[];

  @OneToMany(() => PaymentMethodEntity, (payment) => payment.user)
  paymentMethods!: PaymentMethodEntity[];

  @OneToMany(() => OrderEntity, (order) => order.user)
  orders!: OrderEntity[];

  @OneToMany(() => ReferralEntity, (referral) => referral.referrer)
  referrals!: ReferralEntity[];

  @OneToMany(() => CartEntity, (cart) => cart.user)
  carts!: CartEntity[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
