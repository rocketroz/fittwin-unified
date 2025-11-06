import { Column, CreateDateColumn, Entity, JoinColumn, ManyToOne, PrimaryColumn } from 'typeorm';
import { OrderEntity } from './order.entity';

@Entity({ name: 'checkout_intents' })
export class CheckoutIntentEntity {
  @PrimaryColumn({ name: 'idempotency_key' })
  idempotencyKey!: string;

  @ManyToOne(() => OrderEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'order_id' })
  order!: OrderEntity;

  @Column({ name: 'payload_hash' })
  payloadHash!: string;

  @Column({ name: 'payment_intent_ref' })
  paymentIntentRef!: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
