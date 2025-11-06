import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum ReferralFraudRuleType {
  SELF_PURCHASE = 'self_purchase',
  DUPLICATE_ATTRIBUTION = 'duplicate_attribution',
  SUSPICIOUS_PATTERN = 'suspicious_pattern',
  VELOCITY_CHECK = 'velocity_check',
}

@Entity({ name: 'referral_fraud_rules' })
export class ReferralFraudRuleEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'rule_name', unique: true })
  ruleName!: string;

  @Column({ name: 'rule_type', type: 'enum', enum: ReferralFraudRuleType })
  ruleType!: ReferralFraudRuleType;

  @Column({ default: true })
  enabled!: boolean;

  @Column({ type: 'jsonb' })
  config!: Record<string, unknown>;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
