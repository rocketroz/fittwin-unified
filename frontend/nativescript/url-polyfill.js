const hasNativeURL = typeof globalThis !== 'undefined' && typeof globalThis.URL === 'function';

class BasicURL {
  constructor(input, base) {
    const value = input == null ? '' : String(input);
    const origin = base != null ? String(base) : undefined;

    if (hasNativeURL) {
      try {
        const native = origin ? new globalThis.URL(value, origin) : new globalThis.URL(value);
        this.href = native.href;
        this.protocol = native.protocol;
        this.username = native.username;
        this.password = native.password;
        this.host = native.host;
        this.hostname = native.hostname;
        this.port = native.port;
        this.pathname = native.pathname;
        this.search = native.search;
        this.hash = native.hash;
        this.origin = native.origin;
        return;
      } catch (_err) {
        // fall back to manual parsing below
      }
    }

    this.href = origin ? `${origin.replace(/\/$/, '')}/${value.replace(/^\//, '')}` : value;
    this.protocol = '';
    this.username = '';
    this.password = '';
    this.host = '';
    this.hostname = '';
    this.port = '';
    this.pathname = value;
    this.search = '';
    this.hash = '';
    this.origin = origin || '';
  }

  toString() {
    return this.href;
  }
}

module.exports = {
  URL: hasNativeURL ? globalThis.URL : BasicURL
};
