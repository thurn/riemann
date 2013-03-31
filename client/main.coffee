doc = document.documentElement
navClass = 'nNavOpen'

closeNav = (event) ->
  event.stopPropagation()
  console.log "closeNav"
  $(doc).removeClass(navClass);
  $(".nTopHeader, .nMain").off("click")
  $(".nMenuToggleButton").on("click", openNav)

openNav = (event) ->
  event.stopPropagation()
  console.log "openNav"
  $(doc).addClass(navClass)
  $(".nMenuToggleButton").off("click")
  $(".nTopHeader, .nMain").on("click", closeNav)

Meteor.startup ->
  $(".nMenuToggleButton").on("click", openNav)