# Require all js files inside the 'nyulibraries' subdir next to this file.
#= require jquery
#= require bootstrap-tooltip
#= require bootstrap-popover
#= require bootstrap-transition
#= require bootstrap-collapse
#= require bootstrap-alert
#= require bootstrap-dropdown
#= require nyulibraries/popover
$ ->
  console.log "HELLO!"
  # My Workspace Help Popover
  new window.nyulibraries.PartialHoverPopover("a.nyulibraries-snippet").init()
