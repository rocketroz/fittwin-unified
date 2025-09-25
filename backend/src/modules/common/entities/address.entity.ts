import {
  Column,
  CreateDateColumn,
  DeleteDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { UserProfileEntity } from '../../profiles/entities/user-profile.entity';

enum AddressType {
  BILLING = 'billing',
  SHIPPING = 'shipping'
}

@Entity({ name: 'addresses' })
export class AddressEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => UserProfileEntity, (user) => user.addresses, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'user_id' })
  user?: UserProfileEntity | null;

  @Column({ type: 'enum', enum: AddressType })
  type!: AddressType;

  @Column()
  line1!: string;

  @Column({ nullable: true })
  line2?: string | null;

  @Column()
  city!: string;

  @Column({ nullable: true })
  state?: string | null;

  @Column({ name: 'postal_code' })
  postalCode!: string;

  @Column()
  country!: string;

  @Column({ type: 'jsonb', nullable: true })
  metadata?: Record<string, unknown> | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;

  @DeleteDateColumn({ name: 'deleted_at', type: 'timestamptz', nullable: true })
  deletedAt?: Date | null;
}

export { AddressType };
