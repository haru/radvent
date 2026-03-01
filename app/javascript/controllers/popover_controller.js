import { Controller } from '@hotwired/stimulus'
import * as mdb from 'mdb-ui-kit/js/mdb.es.min.js'

export default class PopoverController extends Controller {
  connect() {
    if (!mdb.Popover.getInstance(this.element)) {
      this.popover = new mdb.Popover(this.element)
    } else {
      this.popover = mdb.Popover.getInstance(this.element)
    }
  }

  disconnect() {
    if (this.popover) {
      this.popover.dispose()
      this.popover = null
    }
  }
}
