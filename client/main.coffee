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

iPhone = ->
  ua = navigator.userAgent
  ~ua.indexOf('iPhone') || ~ua.indexOf('iPod')

iPhoneHideNavbar = ->
  if iPhone()
    height = $(window).height() + 60
    $("body").css(height: height + 'px')
    setTimeout((-> window.scrollTo(0, 0)), 1)

zoom = ->
  width = $(window).width()
  height = $(window).height()
  if iPhone()
    height += 60 # Compensate for the hidden navigation bar on iPhones

  computeScale = (targetWidth, targetHeight) ->
    if width - targetWidth > height - targetHeight
      height / targetHeight
    else
      width / targetWidth

  if width >= 1200 and height >= 800
    return # Do not scale, screen is full-size
  else if width >= 600 and height >= 400 # desktop style
    scaleFactor = computeScale(1200, 800)
    $(".nContainer").css("transform", "scale(#{scaleFactor})")
  else if height >= 356 # mobile portrait style
    scaleFactor = computeScale(320, 356)
    $(".nMain").css("transform", "scale(#{scaleFactor})")
  else # mobile landscape style
    scaleFactor = computeScale(480, 268)
    $(".nMain").css("transform", "scale(#{scaleFactor})")

Meteor.startup ->
  iPhoneHideNavbar()
  $("body").on "orientationchange", ->
    iPhoneHideNavbar()
  zoom()
  $(window).resize(zoom)
