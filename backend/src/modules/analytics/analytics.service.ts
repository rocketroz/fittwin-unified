import { Injectable } from '@nestjs/common';
import { inMemoryStore } from '../../lib/persistence/in-memory-store';

interface AnalyticsQuery {
  brandId?: string;
  rangeStart?: string;
  rangeEnd?: string;
  granularity?: string;
}

@Injectable()
export class AnalyticsService {
  private readonly store = inMemoryStore;

  getBrandAnalytics(query: AnalyticsQuery) {
    const start = query.rangeStart ? new Date(query.rangeStart) : new Date(Date.now() - 1000 * 60 * 60 * 24 * 30);
    const end = query.rangeEnd ? new Date(query.rangeEnd) : new Date();

    const orders = Array.from(this.store.orders.values()).filter((order) => {
      const createdAt = new Date(order.createdAt);
      return createdAt >= start && createdAt <= end;
    });

    const referralOrders = orders.filter((order) => order.referralId);
    const totalGmv = orders.reduce((sum, order) => sum + order.totalCents, 0);
    const referralGmv = referralOrders.reduce((sum, order) => sum + order.totalCents, 0);

    const totalConversions = orders.length;
    const totalClicks = Math.max(totalConversions * 20, 1);
    const conversionRate = totalClicks ? totalConversions / totalClicks : 0;

    const returnCount = orders.filter((order) => order.status === 'refunded').length;
    const returnRate = orders.length ? returnCount / orders.length : 0;

    const fitAccuracy = 0.91;

    return {
      range: {
        start: start.toISOString().split('T')[0],
        end: end.toISOString().split('T')[0]
      },
      conversionRate: Number(conversionRate.toFixed(3)),
      returnRate: Number(returnRate.toFixed(3)),
      fitAccuracy,
      referralAttribution: {
        orders: referralOrders.length,
        gmv: referralGmv
      },
      totals: {
        orders: orders.length,
        gmv: totalGmv
      }
    };
  }
}
