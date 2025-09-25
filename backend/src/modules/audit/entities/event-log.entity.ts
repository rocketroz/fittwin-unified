import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';

enum EventActorType {
  SHOPPER = 'shopper',
  BRAND_ADMIN = 'brand_admin',
  PLATFORM_ADMIN = 'platform_admin',
  SYSTEM = 'system'
}

@Entity({ name: 'event_logs' })
export class EventLogEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'actor_type', type: 'enum', enum: EventActorType })
  actorType!: EventActorType;

  @Column({ name: 'actor_id', type: 'uuid', nullable: true })
  actorId?: string | null;

  @Column()
  action!: string;

  @Column({ name: 'entity_type' })
  entityType!: string;

  @Column({ name: 'entity_id', type: 'uuid' })
  entityId!: string;

  @Column({ type: 'jsonb', nullable: true })
  metadata?: Record<string, unknown> | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}

export { EventActorType };
