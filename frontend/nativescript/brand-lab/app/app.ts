import { Application, Frame, isIOS } from '@nativescript/core';

if (isIOS) {
  require('../../shared/capture/ios');
} else {
  require('../../shared/capture/android');
}

Application.setCssFileName('app.css');
Application.run({
  create: () => {
    const frame = Frame.topmost() ?? new Frame();
    if (!frame.currentEntry) {
      frame.navigate('main-page');
    }
    return frame;
  }
});
