import { Controller } from '@hotwired/stimulus'
import { DataTable } from 'simple-datatables'

export default class DatatableController extends Controller {
  connect() {
    const tableEl = this.element.tagName === 'TABLE'
      ? this.element
      : this.element.querySelector('table')
    if (!tableEl) return

    const headers = Array.from(tableEl.querySelectorAll('thead th'))
    const excludedColumns = headers
      .map((th, i) => th.textContent.trim() === '' ? { select: i, sortable: false, searchable: false } : null)
      .filter(Boolean)

    this.dataTable = new DataTable(tableEl, {
      searchable: true,
      perPage: 10,
      ...(excludedColumns.length ? { columns: excludedColumns } : {})
    })
  }

  disconnect() {
    if (this.dataTable) {
      this.dataTable.destroy()
      this.dataTable = null
    }
  }
}
