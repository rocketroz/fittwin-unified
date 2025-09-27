const path = require('path');
const webpack = require('@nativescript/webpack');

module.exports = (env) => {
  webpack.init(env);

  webpack.chainWebpack((config) => {
    config.plugin('DefinePlugin').tap((args) => {
      const definitions = args[0] ?? {};
      definitions['process.env.NS_LAB_URL'] = JSON.stringify(process.env.NS_LAB_URL || 'http://localhost:3001/ar-lab');
      return [definitions];
    });
    config.resolve.alias.set('url$', path.resolve(__dirname, '../url-polyfill.js'));
  });

  return webpack.resolveConfig();
};
