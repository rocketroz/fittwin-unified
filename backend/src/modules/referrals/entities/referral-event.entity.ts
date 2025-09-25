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

enum ReferralEventType {
  CLICK = 'click',
  CONVERSION = 'conversion',
  FRAUD_FLAG = 'fraud_flag'
}

@Entity({ name: 'referral_events' })
export class ReferralEventEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => ReferralEntity, (referral) => referral.events, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'rid' })
  referral!: ReferralEntity;

  @Column({ name: 'event_type', type: 'enum', enum: ReferralEventType })
  eventType!: ReferralEventType;

  @ManyToOne(() => OrderEntity, { nullable: true })
  @JoinColumn({ name: 'order_id' })
  order?: OrderEntity | null;

  @Column({ name: 'device_fingerprint', nullable: true })
  deviceFingerprint?: string | null;

  @Column({ name: 'ip_hash', nullable: true })
  ipHash?: string | null;

  @Column({ type: 'jsonb', nullable: true })
  metadata?: Record<string, unknown> | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}

export { ReferralEventType };
