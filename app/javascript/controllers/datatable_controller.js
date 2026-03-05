import { Controller } from '@hotwired/stimulus'
import { DataTable } from 'simple-datatables'

export default class DatatableController extends Controller {
  connect() {
    const tableEl = this.element.tagName === 'TABLE'
      ? this.element
      : this.element.querySelector('table')
    if (!tableEl) return
    this.dataTable = new DataTable(tableEl, {
      searchable: true,
      perPage: 10
    })
  }

  disconnect() {
    if (this.dataTable) {
      this.dataTable.destroy()
      this.dataTable = null
    }
  }
}
