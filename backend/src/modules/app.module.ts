import { Module } from '@nestjs/common';
import { AuthModule } from './auth/auth.module';
import { ProfilesModule } from './profiles/profiles.module';
import { TryOnModule } from './tryon/tryon.module';
import { CommerceModule } from './commerce/commerce.module';
import { ReferralsModule } from './referrals/referrals.module';
import { BrandModule } from './brand/brand.module';
import { AnalyticsModule } from './analytics/analytics.module';
import { AuditModule } from './audit/audit.module';

@Module({
  imports: [
    AuthModule,
    ProfilesModule,
    TryOnModule,
    CommerceModule,
    ReferralsModule,
    BrandModule,
    AnalyticsModule,
    AuditModule,
  ],
})
export class AppModule {}
