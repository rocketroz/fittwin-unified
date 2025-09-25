import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { BrandEntity } from './brand.entity';

enum BrandUserRole {
  OWNER = 'owner',
  MANAGER = 'manager',
  ANALYST = 'analyst'
}

enum BrandUserStatus {
  INVITED = 'invited',
  ACTIVE = 'active',
  REVOKED = 'revoked'
}

@Entity({ name: 'brand_users' })
export class BrandUserEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => BrandEntity, (brand) => brand.users, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'brand_id' })
  brand!: BrandEntity;

  @Column({ type: 'citext' })
  email!: string;

  @Column({ type: 'enum', enum: BrandUserRole })
  role!: BrandUserRole;

  @Column({ type: 'enum', enum: BrandUserStatus, default: BrandUserStatus.INVITED })
  status!: BrandUserStatus;

  @Column({ name: 'invite_token', type: 'uuid', nullable: true })
  inviteToken?: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}

export { BrandUserRole, BrandUserStatus };
