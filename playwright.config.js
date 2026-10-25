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
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } }
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
