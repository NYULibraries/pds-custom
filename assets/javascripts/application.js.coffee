# Require all js files inside the 'nyulibraries' subdir next to this file.
#= require application/jquery
#= require bootstrap-tooltip
#= require bootstrap-popover
#= require bootstrap-transition
#= require bootstrap-collapse
#= require bootstrap-alert
#= require bootstrap-dropdown
#= require nyulibraries/popover
$ ->
  console.log "HELLO!"
  # Help Popover
  new window.nyulibraries.HoverPopover("a.nyulibraries-help").init()
  new window.nyulibraries.PartialHoverPopover("a.nyulibraries-help-snippet").init()
