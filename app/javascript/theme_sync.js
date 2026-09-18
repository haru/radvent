// Turbo Drive reuses the existing <html> element across visits, so
// data-theme (set server-side on first load) goes stale after a Turbo
// visit like the post-login redirect. Re-apply it from the <head> meta
// tag, which Turbo does refresh on every visit.
document.addEventListener('turbo:load', () => {
  const meta = document.querySelector('meta[name="theme"]')
  if (meta) {
    document.documentElement.dataset.theme = meta.content
  }
})
