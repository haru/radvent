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
        sessionStorage: 'readonly'
      }
    },
    rules: {
      semi: ['error', 'never'],
      quotes: ['error', 'single'],
      indent: ['error', 2]
    }
  }
]
