const path = require('path');
const directory = path.join(__dirname, '../../build')

module.exports = {
  mode: 'production',
  entry: './src/updater/GeorefUpdate.coffee',
  output: {
    path: path.resolve(directory, 'updater'),
    filename: 'georef-update.js',
    library: 'GeorefUpdate',
    libraryTarget: 'umd',
    globalObject: 'this'
  },
  module: {
    rules: [{
      test: /\.coffee$/,
      loader: 'coffee-loader',
    }, ],
  },
};