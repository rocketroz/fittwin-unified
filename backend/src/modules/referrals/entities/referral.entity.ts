import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryColumn,
} from 'typeorm';
import { UserProfileEntity } from '../../profiles/entities/user-profile.entity';
import { ProductEntity } from '../../catalog/entities/product.entity';
import { ReferralEventEntity } from './referral-event.entity';
import { OrderEntity } from '../../commerce/entities/order.entity';
import { RewardLedgerEntryEntity } from './reward-ledger-entry.entity';

@Entity({ name: 'referrals' })
export class ReferralEntity {
  @PrimaryColumn({ type: 'varchar', length: 64 })
  rid!: string;

  @ManyToOne(() => UserProfileEntity, (user) => user.referrals, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'referrer_user_id' })
  referrer!: UserProfileEntity;

  @ManyToOne(() => ProductEntity, { nullable: true })
  @JoinColumn({ name: 'target_product_id' })
  targetProduct?: ProductEntity | null;

  @Column({ name: 'share_url' })
  shareUrl!: string;

  @Column({ name: 'policy_snapshot', type: 'jsonb' })
  policySnapshot!: Record<string, unknown>;

  @Column({ name: 'expires_at', type: 'timestamptz', nullable: true })
  expiresAt?: Date | null;

  @OneToMany(() => ReferralEventEntity, (event) => event.referral)
  events!: ReferralEventEntity[];

  @OneToMany(() => OrderEntity, (order) => order.referral)
  orders!: OrderEntity[];

  @OneToMany(() => RewardLedgerEntryEntity, (entry) => entry.referral)
  rewardEntries!: RewardLedgerEntryEntity[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
