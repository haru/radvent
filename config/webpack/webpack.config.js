const { generateWebpackConfig, merge } = require('shakapacker')

const webpack = require('webpack')

const baseConfig = generateWebpackConfig()

const customConfig = {
  plugins: [
    new webpack.ProvidePlugin({
      $: 'jquery/src/jquery',
      jQuery: 'jquery/src/jquery'
    })
  ],
  module: {
    rules: [
      {
        test: /\.scss$/,
        use: [
          {
            loader: 'sass-loader',
            options: {
              sassOptions: {
                silenceDeprecations: ['import', 'global-builtin', 'color-functions'],
                quietDeps: true
              }
            }
          }
        ]
      }
    ]
  }
}

// Modify sass-loader options in base config
baseConfig.module.rules.forEach(rule => {
  if (rule.use && Array.isArray(rule.use)) {
    rule.use.forEach(loader => {
      if (loader.loader && loader.loader.includes('sass-loader')) {
        loader.options = loader.options || {}
        loader.options.sassOptions = loader.options.sassOptions || {}
        loader.options.sassOptions.silenceDeprecations = ['import', 'global-builtin', 'color-functions']
        loader.options.sassOptions.quietDeps = true
      }
    })
  }
})

// Only merge plugins, not module rules (we already modified base config directly)
baseConfig.plugins.push(
  new webpack.ProvidePlugin({
    $: 'jquery/src/jquery',
    jQuery: 'jquery/src/jquery'
  })
)

module.exports = baseConfig
