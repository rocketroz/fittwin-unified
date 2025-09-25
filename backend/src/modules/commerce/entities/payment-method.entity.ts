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

@Entity({ name: 'payment_methods' })
export class PaymentMethodEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => UserProfileEntity, (user) => user.paymentMethods, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: UserProfileEntity;

  @OneToMany(() => UserProfileEntity, (user) => user.defaultPaymentMethod)
  defaultProfiles!: UserProfileEntity[];

  @Column({ name: 'psp_token_id' })
  pspTokenId!: string;

  @Column({ nullable: true })
  brand?: string | null;

  @Column({ nullable: true, length: 4 })
  last4?: string | null;

  @Column({ name: 'expires_at', type: 'date', nullable: true })
  expiresAt?: Date | null;

  @ManyToOne(() => AddressEntity, { nullable: true })
  @JoinColumn({ name: 'billing_address_id' })
  billingAddress?: AddressEntity | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
