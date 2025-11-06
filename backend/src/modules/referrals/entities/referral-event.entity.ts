import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { ReferralEntity } from './referral.entity';
import { OrderEntity } from '../../commerce/entities/order.entity';
import { UserProfileEntity } from '../../profiles/entities/user-profile.entity';

export enum ReferralEventType {
  CLICK = 'click',
  SIGNUP = 'signup',
  PURCHASE = 'purchase',
  REWARD_ISSUED = 'reward_issued',
}

@Entity({ name: 'referral_events' })
export class ReferralEventEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => ReferralEntity, (referral) => referral.events, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'referral_id' })
  referral!: ReferralEntity;

  @Column({ name: 'event_type', type: 'enum', enum: ReferralEventType })
  eventType!: ReferralEventType;

  @ManyToOne(() => UserProfileEntity, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'user_id' })
  user?: UserProfileEntity | null;

  @ManyToOne(() => OrderEntity, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'order_id' })
  order?: OrderEntity | null;

  @Column({ default: false })
  attributed!: boolean;

  @Column({ name: 'fraud_check_passed', default: true })
  fraudCheckPassed!: boolean;

  @Column({ type: 'jsonb', nullable: true })
  metadata?: Record<string, unknown> | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
