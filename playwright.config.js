import { defineConfig, devices } from '@playwright/test'

// Keep in sync with the port in build-scripts/e2e-server.sh.
const baseURL = 'http://127.0.0.1:4500'

export default defineConfig({
  testDir: 'e2e',
  workers: 1,
  retries: 0,
  forbidOnly: true,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL,
    locale: 'ja-JP',
    timezoneId: 'Asia/Tokyo',
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure'
  },
  // The main journey signs up alice and bob first; setup adds the other accounts; the remaining
  // specs only rely on those accounts and create their own boards.
  projects: [
    { name: 'journey', testMatch: 'user-journey.spec.js', use: { ...devices['Desktop Chrome'] } },
    {
      name: 'setup',
      testMatch: 'setup.spec.js',
      dependencies: ['journey'],
      use: { ...devices['Desktop Chrome'] }
    },
    {
      name: 'scenarios',
      testIgnore: ['user-journey.spec.js', 'setup.spec.js'],
      dependencies: ['setup'],
      use: { ...devices['Desktop Chrome'] }
    }
  ],
  webServer: {
    command: 'sh build-scripts/e2e-server.sh',
    url: `${baseURL}/`,
    reuseExistingServer: false,
    // Covers the asset build and the database reset on a cold machine.
    timeout: 300_000,
    stdout: 'pipe'
  }
})
