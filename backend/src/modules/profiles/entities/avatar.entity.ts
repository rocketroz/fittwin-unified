import {
  Column,
  CreateDateColumn,
  DeleteDateColumn,
  Entity,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { UserProfileEntity } from './user-profile.entity';

enum AvatarStatus {
  PROCESSING = 'processing',
  READY = 'ready',
  FAILED = 'failed'
}

@Entity({ name: 'avatars' })
export class AvatarEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => UserProfileEntity, (user) => user.avatars, { onDelete: 'CASCADE' })
  user!: UserProfileEntity;

  @Column()
  version!: number;

  @Column({ type: 'jsonb' })
  sources!: Record<string, unknown>;

  @Column({ name: 'mesh_ref', nullable: true })
  meshRef?: string | null;

  @Column({ type: 'enum', enum: AvatarStatus, default: AvatarStatus.PROCESSING })
  status!: AvatarStatus;

  @Column({ name: 'generated_at', type: 'timestamptz', nullable: true })
  generatedAt?: Date | null;

  @Column({ type: 'smallint', nullable: true })
  confidence?: number | null;

  @DeleteDateColumn({ name: 'deleted_at', type: 'timestamptz', nullable: true })
  deletedAt?: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}

export { AvatarStatus };
