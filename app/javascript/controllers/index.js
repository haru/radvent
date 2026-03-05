import { application } from './application'
import MarkdownController from './markdown_controller'
import CommentController from './comment_controller'
import EditorController from './editor_controller'
import DatatableController from './datatable_controller'
import PopoverController from './popover_controller'
import NavbarDropdownController from './navbar_dropdown_controller'

application.register('markdown', MarkdownController)
application.register('comment', CommentController)
application.register('editor', EditorController)
application.register('datatable', DatatableController)
application.register('popover', PopoverController)
application.register('navbar-dropdown', NavbarDropdownController)

export { application }
