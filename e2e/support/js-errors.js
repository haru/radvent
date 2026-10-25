import { expect } from '@playwright/test'

// Uncaught exceptions and console errors raised in any page of the current test.
const errors = []

function listen(page) {
  page.on('pageerror', (error) => errors.push(`pageerror at ${page.url()}: ${error.message}`))
  page.on('console', (message) => {
    // A 4xx/5xx answer is reported by the browser as a console error too. Those are part of the
    // scenarios (wrong password, hidden article) and are asserted on the page itself.
    if (message.type() === 'error' && !message.text().startsWith('Failed to load resource: the server responded')) {
      errors.push(`console.error at ${page.url()}: ${message.text()}`)
    }
  })
}

// Starts collecting errors from every page (popups included) of the context.
export function watchJsErrors(context) {
  context.pages().forEach(listen)
  context.on('page', listen)
}

export function clearJsErrors() {
  errors.length = 0
}

export function expectNoJsErrors() {
  expect(errors).toEqual([])
}
