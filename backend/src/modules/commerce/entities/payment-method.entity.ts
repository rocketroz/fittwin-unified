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

export enum PaymentMethodType {
  CARD = 'card',
  BANK_ACCOUNT = 'bank_account',
  OTHER = 'other',
}

@Entity({ name: 'payment_methods' })
export class PaymentMethodEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => UserProfileEntity, (user) => user.paymentMethods, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: UserProfileEntity;

  @OneToMany(() => UserProfileEntity, (user) => user.defaultPaymentMethod)
  defaultProfiles!: UserProfileEntity[];

  @Column({ default: 'stripe' })
  provider!: string;

  @Column({ name: 'provider_payment_method_id' })
  providerPaymentMethodId!: string;

  @Column({ type: 'enum', enum: PaymentMethodType })
  type!: PaymentMethodType;

  @Column({ nullable: true })
  brand?: string | null;

  @Column({ nullable: true, length: 4 })
  last4?: string | null;

  @Column({ name: 'exp_month', type: 'int', nullable: true })
  expMonth?: number | null;

  @Column({ name: 'exp_year', type: 'int', nullable: true })
  expYear?: number | null;

  @Column({ name: 'is_default', default: false })
  isDefault!: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
