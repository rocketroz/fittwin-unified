import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { UserProfileEntity } from '../../profiles/entities/user-profile.entity';

export enum AddressType {
  SHIPPING = 'shipping',
  BILLING = 'billing',
  BOTH = 'both',
}

@Entity({ name: 'addresses' })
export class AddressEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => UserProfileEntity, (user) => user.addresses, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: UserProfileEntity;

  @Column({ name: 'type', type: 'enum', enum: AddressType })
  type!: AddressType;

  @Column({ name: 'full_name' })
  fullName!: string;

  @Column({ name: 'address_line1' })
  addressLine1!: string;

  @Column({ name: 'address_line2', nullable: true })
  addressLine2?: string | null;

  @Column()
  city!: string;

  @Column({ name: 'state_province' })
  stateProvince!: string;

  @Column({ name: 'postal_code' })
  postalCode!: string;

  @Column()
  country!: string;

  @Column({ nullable: true })
  phone?: string | null;

  @Column({ name: 'is_default', default: false })
  isDefault!: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
