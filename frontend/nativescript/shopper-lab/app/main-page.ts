import { Observable, EventData, Page, WebView, ApplicationSettings, isAndroid } from '@nativescript/core';
import { LoadEventData } from '@nativescript/core/ui/web-view';

declare const android: any;

const DEFAULT_LAB_URL = (process.env.NS_LAB_URL as string) || 'http://localhost:3001/ar-lab';
const LAB_URL_KEY = 'lab.url';

class MainViewModel extends Observable {
  labUrl: string;
  statusMessage = '';

  constructor() {
    super();
    const stored = ApplicationSettings.getString(LAB_URL_KEY, DEFAULT_LAB_URL);
    this.labUrl = stored;
    this.set('labUrl', stored);
    this.set('statusMessage', '');
  }

  setLabUrl(url: string) {
    this.labUrl = url;
    this.set('labUrl', url);
    ApplicationSettings.setString(LAB_URL_KEY, url);
    this.setStatus(`Loading ${formatUrl(url)}…`);
  }

  setStatus(message?: string) {
    this.set('statusMessage', message ?? '');
  }
}

export function navigatingTo(args: EventData) {
  const page = args.object as Page;
  page.bindingContext = new MainViewModel();
  wireWebView(page);
}

export function onSubmitUrl(args: EventData) {
  const page = (args.object as any).page as Page;
  const model = page.bindingContext as MainViewModel;
  const textField = page.getViewById('labUrlEntry') as any;
  const url = textField?.text?.trim();
  if (url) {
    model.setLabUrl(url);
    const webView = page.getViewById('labWebView') as WebView;
    if (webView) {
      webView.stopLoading();
      webView.src = url;
    }
  }
}

function wireWebView(page: Page) {
  const webView = page.getViewById('labWebView') as WebView | undefined;
  if (!webView || (webView as any).__fittwinBound) {
    return;
  }

  (webView as any).__fittwinBound = true;

  webView.on('loaded', () => {
    configureAndroidWebView(webView);
  });

  webView.on('loadStarted', (event: LoadEventData) => {
    const model = page.bindingContext as MainViewModel;
    model?.setStatus(`Loading ${formatUrl(event.url)}…`);
    console.log(`[Lab WebView] Loading ${event.url}`);
  });

  webView.on('loadFinished', (event: LoadEventData) => {
    const model = page.bindingContext as MainViewModel;
    if (event.error) {
      model?.setStatus(`Failed to load: ${event.error}`);
      console.error(`[Lab WebView] Failed loading ${event.url}: ${event.error}`);
    } else {
      model?.setStatus('');
      console.log(`[Lab WebView] Loaded ${event.url}`);
    }
  });
}

function formatUrl(url?: string) {
  if (!url) {
    return 'resource';
  }
  return url.replace(/^https?:\/\//, '');
}

function configureAndroidWebView(webView: WebView) {
  if (!isAndroid) {
    return;
  }

  const nativeView = webView.android;
  if (!nativeView || (nativeView as any).__fittwinConfigured) {
    return;
  }

  (nativeView as any).__fittwinConfigured = true;

  const settings = nativeView.getSettings();
  settings.setJavaScriptEnabled(true);
  settings.setDomStorageEnabled(true);
  settings.setMediaPlaybackRequiresUserGesture(false);
  settings.setAllowFileAccess(true);
  settings.setAllowContentAccess(true);

  if (android.os.Build.VERSION.SDK_INT >= 21) {
    settings.setMixedContentMode(android.webkit.WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);
  }

  const ChromeClient = android.webkit.WebChromeClient.extend('FitTwinLabChromeClient', {
    onPermissionRequest(request: android.webkit.PermissionRequest) {
      try {
        request.grant(request.getResources());
      } catch (err) {
        console.error('[Lab WebView] Permission request failed', err);
      }
    },
    onGeolocationPermissionsShowPrompt(origin: string, callback: any) {
      callback.invoke(origin, true, false);
    }
  });

  nativeView.setWebChromeClient(new ChromeClient());
  nativeView.setWebViewClient(new android.webkit.WebViewClient());

  if (android.os.Build.VERSION.SDK_INT >= 19) {
    android.webkit.WebView.setWebContentsDebuggingEnabled(true);
  }
}
