import { Application, Frame } from '@nativescript/core';

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
