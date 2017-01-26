var path = require('path');
var webpack = require('webpack');
var merge = require('webpack-merge');
var HtmlWebpackPlugin = require('html-webpack-plugin');
var autoprefixer = require('autoprefixer');
var ExtractTextPlugin = require('extract-text-webpack-plugin');
var CopyWebpackPlugin = require('copy-webpack-plugin');
var entryPath = path.join(__dirname, 'src/static/index.js');
var outputPath = path.join(__dirname, 'dist');

var TARGET_ENV = process.env.npm_lifecycle_event === 'build' ? 'production' : 'development';
var outputFilename = TARGET_ENV === 'production' ? '[name]-[hash].js' : '[name].js'

var base = {
    output: {
        path: outputPath,
        filename: path.join('static/js/', outputFilename),
        publicPath: '/'
    },
    resolve: {
        extensions: ['', '.js', '.elm']
    },
    module: {
        noParse: /\.elm$/,
        loaders: [{
            test: /\.(eot|ttf|woff|woff2|svg)$/,
            loader: 'file-loader'
        }]
    },
    plugins: [
        new HtmlWebpackPlugin({
            template: 'src/static/index.html',
            inject: 'body',
            filename: 'index.html'
        })
    ],
    postcss: [autoprefixer({
        browsers: ['last 2 versions']
    })],
}

if (TARGET_ENV === 'development') {
    module.exports = merge(base, {
        entry: [
            'webpack-dev-server/client?http://localhost:8080',
            entryPath
        ],
        devServer: {
            historyApiFallback: true,
        },
        module: {
            loaders: [{
                    test: /\.elm$/,
                    exclude: [/elm-stuff/, /node_modules/],
                    loader: 'elm-hot!elm-webpack?verbose=true&warn=true&debug=true'
                },
                {
                    test: /\.(css|scss)$/,
                    loaders: [
                        'style-loader',
                        'css-loader',
                        'postcss-loader',
                        'sass-loader'
                    ]
                }
            ]
        }
    });
}

if (TARGET_ENV === 'production') {
    module.exports = merge(base, {
        entry: entryPath,
        module: {
            loaders: [{
                    test: /\.elm$/,
                    exclude: [/elm-stuff/, /node_modules/],
                    loader: 'elm-webpack'
                },
                {
                    test: /\.(css|scss)$/,
                    loader: ExtractTextPlugin.extract('style-loader', [
                        'css-loader',
                        'postcss-loader',
                        'sass-loader'
                    ])
                }
            ]
        },
        plugins: [
            new CopyWebpackPlugin([{
                    from: 'src/static/img/',
                    to: 'static/img/'
                },
                {
                    from: 'src/android-chrome-192x192.png'
                },
                {
                    from: 'src/android-chrome-512x512.png'
                },
                {
                    from: 'src/apple-touch-icon.png'
                },
                {
                    from: 'src/browserconfig.xml'
                },
                {
                    from: 'src/favicon-16x16.png'
                },
                {
                    from: 'src/favicon-32x32.png'
                },
                {
                    from: 'src/favicon.ico'
                },
                {
                    from: 'src/manifest.json'
                },
                {
                    from: 'src/mstile-144x144.png'
                },
                {
                    from: 'src/mstile-150x150.png'
                },
                {
                    from: 'src/mstile-310x150.png'
                },
                {
                    from: 'src/mstile-310x310.png'
                },
                {
                    from: 'src/mstile-70x70.png'
                },
                {
                    from: 'src/safari-pinned-tab.svg'
                }
            ]),
            new webpack.optimize.OccurenceOrderPlugin(),
            new ExtractTextPlugin('static/css/[name]-[hash].css', {
                allChunks: true
            }),
            new webpack.optimize.UglifyJsPlugin({
                minimize: true,
                compressor: {
                    warnings: false
                }
            })
        ]
    });
}
