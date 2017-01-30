const path = require('path');
const webpack = require('webpack');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = {
  entry: path.join(__dirname, 'index.js'),
  output: {
    filename: "[name].js",
    path: "dist",
    publicPath: ""
  },
  target: 'node',
  module: {
    loaders: [
      {
        test: /\.cmd$/,
        loader: "file-loader"
      },
      { test: /\.json$/, loader: 'json-loader' }
    ]
  },
  plugins: [
    new CopyWebpackPlugin([
      { from: 'scripts', to: 'scripts' },
      { from: 'config', to: 'config'}
    ])
  ],
}
