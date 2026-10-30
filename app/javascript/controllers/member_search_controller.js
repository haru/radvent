import { Controller } from '@hotwired/stimulus'

const MIN_QUERY_LENGTH = 2
const DEBOUNCE_MS = 300
const REQUEST_TIMEOUT_MS = 10000
const OPTION_SELECTOR = '[role="option"]'

// Incremental search for the member form: shows candidate users as the user types and
// puts the picked user's id into a hidden field. Nothing is added until the form is submitted.
export default class MemberSearchController extends Controller {
  static targets = ['input', 'userId', 'results', 'message']
  static values = {
    url: String,
    rateLimitedMessage: String,
    searchFailedMessage: String,
    sessionExpiredMessage: String,
    notPermittedMessage: String
  }

  // Runs for every instance, so a page restored by Turbo never starts with undefined state.
  initialize() {
    this.composing = false
    this.activeIndex = -1
  }

  // A Turbo snapshot may carry an open (and stale) candidate list.
  connect() {
    this.close()
  }

  disconnect() {
    this.cancelPending()
  }

  // Any edit drops the selection and the old candidates at once (no debounce), so neither a stale id
  // nor a stale candidate can be submitted or picked while the next search is pending.
  input() {
    this.userIdTarget.value = ''
    this.clearMessage()
    this.close()
    this.cancelPending()
    if (!this.composing) this.scheduleSearch()
  }

  compositionStart() {
    this.composing = true
    this.cancelPending()
  }

  compositionEnd() {
    this.composing = false
    this.scheduleSearch()
  }

  keydown(event) {
    // The Enter that confirms an IME conversion must not pick a candidate or submit the form.
    if (event.isComposing || event.keyCode === 229) return

    if (event.key === 'ArrowDown') {
      this.move(event, 1)
    } else if (event.key === 'ArrowUp') {
      this.move(event, -1)
    } else if (event.key === 'Enter') {
      this.enter(event)
    } else if (event.key === 'Escape') {
      this.dismiss()
    }
  }

  choose(event) {
    const option = event.target.closest(OPTION_SELECTOR)
    if (option) this.select(option)
  }

  // Keeps focus in the input while a candidate is clicked, so closing on blur cannot swallow the click.
  keepFocus(event) {
    event.preventDefault()
  }

  // Closes the list and drops any search still waiting or in flight, so it cannot reopen the list.
  dismiss() {
    this.cancelPending()
    this.close()
  }

  close() {
    this.resultsTarget.innerHTML = ''
    this.resultsTarget.hidden = true
    this.activeIndex = -1
    this.inputTarget.setAttribute('aria-expanded', 'false')
    this.inputTarget.removeAttribute('aria-activedescendant')
  }

  scheduleSearch() {
    this.cancelPending()
    this.timer = setTimeout(() => this.search(), DEBOUNCE_MS)
  }

  async search() {
    const query = this.inputTarget.value.trim()
    if (query.length < MIN_QUERY_LENGTH) {
      this.close()
      return
    }

    this.abortController = new AbortController()
    const signal = AbortSignal.any([this.abortController.signal, AbortSignal.timeout(REQUEST_TIMEOUT_MS)])
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set('member_query', query)

    let html
    try {
      const response = await fetch(url, { headers: { Accept: 'text/html' }, redirect: 'manual', signal })
      if (response.status === 204) return this.close()
      const failure = this.failureMessage(response)
      if (failure) {
        console.error('Member search failed', response.status, response.type)
        return this.fail(failure)
      }
      html = await response.text()
    } catch (error) {
      // Only a deliberate cancel (newer input, Esc, blur) is silent; a timeout is a failure.
      if (error.name === 'AbortError') return
      console.error('Member search request failed', error)
      return this.fail(this.searchFailedMessageValue)
    }
    this.show(html)
  }

  // The message for an answer that is not a candidate list, or undefined for a usable one.
  failureMessage(response) {
    // A signed-out session redirects to sign-in; show that as a failure, not as results.
    if (response.type === 'opaqueredirect') return this.sessionExpiredMessageValue
    if (response.status === 429) return this.rateLimitedMessageValue
    if (response.status === 403 || response.status === 404) return this.notPermittedMessageValue
    if (!response.ok || !(response.headers.get('Content-Type') || '').includes('text/html')) {
      return this.searchFailedMessageValue
    }
    return undefined
  }

  show(html) {
    this.close()
    this.clearMessage()
    this.resultsTarget.innerHTML = html
    this.resultsTarget.hidden = false
    this.inputTarget.setAttribute('aria-expanded', 'true')
  }

  fail(message) {
    this.close()
    this.messageTarget.textContent = message
    this.messageTarget.hidden = false
  }

  clearMessage() {
    this.messageTarget.textContent = ''
    this.messageTarget.hidden = true
  }

  cancelPending() {
    clearTimeout(this.timer)
    this.abortController?.abort()
  }

  options() {
    return Array.from(this.resultsTarget.querySelectorAll(OPTION_SELECTOR))
  }

  move(event, step) {
    const options = this.options()
    if (options.length === 0) return
    event.preventDefault()
    // Nothing is highlighted yet (-1): ArrowUp starts from the last candidate.
    const next = this.activeIndex === -1 && step < 0 ? options.length - 1 : (this.activeIndex + step + options.length) % options.length
    this.highlight(next)
  }

  enter(event) {
    const option = this.options()[this.activeIndex]
    if (!option) return
    event.preventDefault()
    this.select(option)
  }

  highlight(index) {
    const options = this.options()
    options.forEach((option, i) => {
      option.classList.toggle('active', i === index)
      option.setAttribute('aria-selected', String(i === index))
    })
    this.activeIndex = index
    this.inputTarget.setAttribute('aria-activedescendant', options[index].id)
    options[index].scrollIntoView({ block: 'nearest' })
  }

  select(option) {
    this.cancelPending()
    this.userIdTarget.value = option.dataset.memberSearchUserId
    this.inputTarget.value = option.dataset.memberSearchLabel
    this.close()
    this.inputTarget.focus()
  }
}
