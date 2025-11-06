import { EventData, Page } from '@nativescript/core';
import { NativeCaptureViewModel } from '../../shared/capture/nativeCaptureViewModel';

export function navigatingTo(args: EventData) {
  const page = args.object as Page;
  page.bindingContext = new NativeCaptureViewModel();
}

export function onStartCapture(args: EventData) {
  const page = (args.object as any).page as Page;
  const model = page.bindingContext as NativeCaptureViewModel;
  model?.startCapture();
}
