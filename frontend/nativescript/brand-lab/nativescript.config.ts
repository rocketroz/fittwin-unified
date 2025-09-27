  import { NativeScriptConfig } from '@nativescript/core';

  export default {
    id: 'com.fittwin.brand.lab',
    appPath: 'app',
    main: 'app/app',
    appResourcesPath: 'app/App_Resources',
    android: { v8Flags: '--expose_gc', markingMode: 'none' }
  } satisfies NativeScriptConfig;
