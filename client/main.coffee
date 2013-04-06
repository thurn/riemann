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

ua = navigator.userAgent
iphone = ~ua.indexOf('iPhone') || ~ua.indexOf('iPod')

iPhoneHideNavbar = ->
  if iphone
    height = document.documentElement.clientHeight + 64
    $("body").css(height: height + 'px')
    setTimeout((-> window.scrollTo(0, 0)), 1)

Meteor.startup ->
  iPhoneHideNavbar()
  $("body").on "orientationchange", ->
    iPhoneHideNavbar()
