import js from '@eslint/js'

export default [
  {
    ignores: ['vendor/**', 'node_modules/**', 'app/assets/builds/**', 'public/**']
  },
  js.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        window: 'readonly',
        document: 'readonly',
        FormData: 'readonly',
        fetch: 'readonly',
        navigator: 'readonly',
        localStorage: 'readonly',
        sessionStorage: 'readonly',
        setTimeout: 'readonly',
        clearTimeout: 'readonly',
        AbortController: 'readonly',
        AbortSignal: 'readonly',
        URL: 'readonly',
        console: 'readonly'
      }
    },
    rules: {
      semi: ['error', 'never'],
      quotes: ['error', 'single'],
      indent: ['error', 2]
    }
  },
  {
    files: ['e2e/**/*.js'],
    languageOptions: {
      // Used inside page.evaluate callbacks, which run in the browser.
      globals: {
        CompositionEvent: 'readonly',
        InputEvent: 'readonly',
        KeyboardEvent: 'readonly'
      }
    }
  }
]
