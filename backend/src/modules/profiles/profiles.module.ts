import { Module } from '@nestjs/common';
import { ProfileService } from './profile.service';
import { AvatarService } from './avatar.service';
import { ProfileController } from './profile.controller';

@Module({
  providers: [ProfileService, AvatarService],
  controllers: [ProfileController],
  exports: [ProfileService, AvatarService]
})
export class ProfilesModule {}
