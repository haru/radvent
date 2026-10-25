const pad = (n) => String(n).padStart(2, '0')
const format = (year, month, day) => `${year}-${pad(month)}-${pad(day)}`

// Today's date in Tokyo (the server's time zone), independent of the time zone Node runs in.
export function tokyoToday(now = new Date()) {
  const [year, month, day] = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Tokyo' })
    .format(now)
    .split('-')
    .map(Number)
  return { year, month, day }
}

// Whole previous month: every article slot is already published.
export function pastEventPeriod(today = tokyoToday()) {
  const year = today.month === 1 ? today.year - 1 : today.year
  const month = today.month === 1 ? 12 : today.month - 1
  const lastDay = new Date(Date.UTC(year, month, 0)).getUTCDate()
  return { start: format(year, month, 1), end: format(year, month, lastDay), lastDay }
}

// Days 1-7 of the same month two years ahead: never published during the run.
export function futureEventPeriod(today = tokyoToday()) {
  const year = today.year + 2
  return { start: format(year, today.month, 1), end: format(year, today.month, 7) }
}
