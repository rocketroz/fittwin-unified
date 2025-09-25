import { EventEmitter } from 'events';
import { generateId, timestamp } from '../persistence/in-memory-store';

export type QueueName = 'avatar-generation' | 'tryon-render';

export interface QueueJob<T = Record<string, unknown>> {
  id: string;
  name: QueueName;
  data: T;
  enqueuedAt: string;
}

export type QueueHandler<T = Record<string, unknown>> = (job: QueueJob<T>) => Promise<void> | void;

class LocalQueue {
  private readonly emitter = new EventEmitter();

  register<T>(queue: QueueName, handler: QueueHandler<T>) {
    this.emitter.on(queue, handler as QueueHandler);
  }

  enqueue<T>(queue: QueueName, data: T): QueueJob<T> {
    const job: QueueJob<T> = {
      id: generateId(),
      name: queue,
      data,
      enqueuedAt: timestamp()
    };
    setTimeout(() => {
      this.emitter.emit(queue, job);
    }, 25);
    return job;
  }
}

export const localQueue = new LocalQueue();
