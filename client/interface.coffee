noughts.closeNav = (event) ->
  return unless $("body").hasClass("nNavOpen");
  event.stopPropagation() if event?
  $("body").removeClass("nNavOpen");
  $(".nHeader, .nMain").off("click")
  $(".nMenuToggleButton").off("click")
  #$(".nMenuToggleButton").on("click", noughts.openNav)
  $(".nMenuToggleButton").tappable(noughts.openNav)

noughts.openNav = (event) ->
  return if $("body").hasClass("nNavOpen");
  event.stopPropagation() if event?
  $("body").addClass("nNavOpen")
  $(".nMenuToggleButton").off("click")
  $(".nMenuToggleButton").on("click", noughts.closeNav)
  $(".nHeader, .nMain").on("click", noughts.closeNav)

Meteor.startup ->
  $(".nMenuToggleButton").tappable(noughts.openNav)

isiPhone = ->
  ua = navigator.userAgent
  ~ua.indexOf('iPhone') || ~ua.indexOf('iPod')

iPhoneHideNavbar = ->
  if isiPhone()
    height = $(window).height() + 60
    $("body").css(height: height + 'px')
    setTimeout((-> window.scrollTo(0, 0)), 1)

widthAndHeight = ->
  width = $(window).width()
  height = $(window).height()
  height += 60 if isiPhone() # Compensate for the hidden navigation bar on iPhones
  return {width: width, height: height}

# Possible UI mode CSS classes
noughts.Mode =
  DESKTOP: "nDesktopMode"
  PORTRAIT: "nPortraitMode"
  LANDSCAPE: "nLandscapeMode"

isMobileMode = -> getInterfaceMode() != noughts.Mode.DESKTOP

# Computes which of the three UI modes (Desktop, Portrait, Landscape) should be
# used, based on the current window height and width.
getInterfaceMode = ->
  {width: width, height: height} = widthAndHeight()

  # Desktop mode triggers for screens bigger than 600x600, otherwise the mode
  # just depends on whether width or height is larger.
  if width > 600 and height > 600
    return noughts.Mode.DESKTOP
  else if width > height
    return noughts.Mode.LANDSCAPE
  else
    return noughts.Mode.PORTRAIT

# Each noughts.Mode interface mode has a "target screen size" which it is
# designed for. In order to make other screen sizes fit, we use a linear scale
# factor to resize the interface based on whichever dimension is further from
# the target.
computeScaleFactor = ->
  mode = getInterfaceMode()
  {width: width, height: height} = widthAndHeight()

  # Computes the ratio of whichever of the current width and height are
  # further from the provided targets.
  computeScale = (targetWidth, targetHeight) ->
    heightRatio = height / targetHeight
    widthRatio = width / targetWidth
    if heightRatio > widthRatio then widthRatio else heightRatio

  result =
    if width > 1200 and height > 768 # Full size, no scaling required
      1
    else
      switch mode
        when noughts.Mode.DESKTOP then computeScale(1200, 768)
        when noughts.Mode.LANDSCAPE then computeScale(804, 702)
        when noughts.Mode.PORTRAIT then computeScale(640, 732)
  Session.set("scaleFactor", result)
  return result

# Adds classes to the <html> element corresponding to the current interface
# mode.
setInterfaceModeClass = ->
  # Clear any pre-existing mode classes
  $("html").removeClass()

  mode = getInterfaceMode()
  $("html").addClass(mode)
  if isMobileMode()
    $("html").addClass("nMobile")

# Scales the interface by setting the font-size attribute on the root <html>
# element and by directling applying css scaling transformation to elements
# with the 'nScale' class.
scaleInterface = ->
  return if Session.get("disableScaling")
  setInterfaceModeClass()
  scale = computeScaleFactor()
  $("html").css({"font-size": "#{scale*100}%"})
  $(".nScale").css
    "-webkit-transform": "scale(#{scale})"
    "-moz-transform": "scale(#{scale})"
    "-o-transform": "scale(#{scale})"
    "-ms-transform": "scale(#{scale})"
    "transform": "scale(#{scale})"

Meteor.startup ->
  iPhoneHideNavbar()
  scaleInterface()

  $(window).on "orientationchange", ->
    iPhoneHideNavbar()
    scaleInterface()

  rescale = null
  $(window).on "resize", ->
    clearTimeout(rescale)
    rescale = setTimeout((-> scaleInterface()), 25)
