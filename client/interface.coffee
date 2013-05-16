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

transformCss = (argument) ->
  "-webkit-transform": argument
  "-moz-transform": argument
  "-o-transform": argument
  "-ms-transform": argument
  "transform": argument

noughts.centeredBlockCss = (scale, width, height, position = "relative") ->
  "height": "#{scale * height}px"
  "width": "#{scale * width}px"
  "margin-top": "#{-((scale * height)/2)}px"
  "margin-left": "#{-((scale * width)/2)}px"
  "top": "50%"
  "left": "50%"
  "position": position

widthHeightCss = (scale, width, height) ->
  "width": "#{width * scale}px"
  "height": "#{height * scale}px"

noughts.useMobileStyle = -> $(window).width() < 600 or $(window).height() < 600

noughts.mobilePortrait = ->
  width = $(window).width()
  height = $(window).height()
  (height > 356 and height < 599) or width < 479


widthAndHeight = ->
  width = $(window).width()
  height = $(window).height()
  height += 60 if iPhone() # Compensate for the hidden navigation bar on iPhones
  return {width: width, height: height}

# Possible UI modes
noughts.Mode =
  DESKTOP: "nDesktopMode"
  PORTRAIT: "nPortraitMode"
  LANDSCAPE: "nLandscapeMode"

# Computes which of the three UI modes (Desktop, Portrait, Landscape) should be
# used, based on the current window height and width.
noughts.getInterfaceMode = ->
  {width: width, height: height} = widthAndHeight()

  # Desktop mode triggers for screens bigger than 900x600, otherwise the mode
  # just depends on whether width or height is larger.
  if width > 900 and height > 600
    return noughts.Mode.DESKTOP
  else if width > height
    return noughts.Mode.LANDSCAPE
  else
    return noughts.Mode.PORTRAIT

# Each noughts.Mode interface mode has a "target screen size" which it is
# designed for. In order to make other screen sizes fit, we use a linear scale
# factor to resize the interface based on whichever dimension is further from
# the target.
noughts.computeScaleFactor = ->
  mode = noughts.getInterfaceMode()
  {width: width, height: height} = widthAndHeight()

  # Computes the ratio of whichever of the current width and height are
  # further from the provided targets.
  computeScale = (targetWidth, targetHeight) ->
    heightRatio = height / targetHeight
    widthRatio = width / targetWidth
    if heightRatio > widthRatio then widthRatio else heightRatio

  return 1 if width > 1200 and height > 768 # Full size, no scaling required

  switch mode
    when noughts.Mode.DESKTOP then return computeScale(1200, 768)
    when noughts.Mode.LANDSCAPE then return computeScale(268, 234)
    when noughts.Mode.PORTRAIT then return computeScale(320, 366)

computeScaleFactor = ->
  width = $(window).width()
  height = $(window).height()
  if iPhone()
    height += 60 # Compensate for the hidden navigation bar on iPhones


  if width >= 1200 and height >= 800
    return 1.0 # Full size, scaling not required
  else if width >= 600 and height >= 600 # desktop style
    return computeScale(1200, 800)
  else if height >= 356 # mobile portrait style
    return computeScale(640, 712)
  else # mobile landscape style
    return computeScale(1200, 670)

CONTAINER_HEIGHT = 768
CONTAINER_WIDTH = 1064
MAIN_WIDTH = 640
MAIN_HEIGHT = CONTAINER_HEIGHT
NAVIGATION_WIDTH = 400
NAVIGATION_HEIGHT = CONTAINER_HEIGHT
MOBILE_HEADER_SIZE = 45

scaleInterface = ->
  scale = computeScaleFactor()
  Session.set("scaleFactor", scale)
  $(".nGame").css(transformCss("scale(#{scale})"))
  if $(window).height() < 356
    # Landscape
    $(".nNotification").css({width: (MAIN_WIDTH/2) * scale})
  else
    $(".nNotification").css({width: MAIN_WIDTH * scale})
  $(".nNotification").css(transformCss("scale(#{scale})"))
  unless noughts.useMobileStyle()
    $(".nContainer").css(noughts.centeredBlockCss(scale, CONTAINER_WIDTH,
        CONTAINER_HEIGHT, "fixed"))
    $(".nMain").css(widthHeightCss(scale, MAIN_WIDTH, MAIN_HEIGHT))
    mainLeft = NAVIGATION_WIDTH + (CONTAINER_WIDTH - NAVIGATION_WIDTH - MAIN_WIDTH)
    $(".nMain").css({left: "#{mainLeft * scale}px"})
    $(".nNavigation").css(widthHeightCss(scale, NAVIGATION_WIDTH,
        NAVIGATION_HEIGHT))
    $(".nLogoContainer").css(transformCss("scale(#{scale})"))

# Grab most of the DOM (except for <canvas>) and scale "size" attributes by
# the provided scaling factor.
zoom = (scaleFactor) ->
  scaleProperty = (element, property) ->
    propertyString = element.css(property)
    value = parseFloat(propertyString)
    return if isNaN(value)
    element.css(property, value * scaleFactor)

  properties = ["height", "width", "margin-top", "margin-right",
      "margin-bottom", "margin-left", "padding-top", "padding-right",
      "padding-bottom", "padding-left"]

  $("div,nav,header,button").each ->
    for property in properties
      scaleProperty($(this), property)

  # Keep in sync with main.less
  DEFAULT_FONT_SIZE = 26
  $(".nDefaultFont").css("font-size", DEFAULT_FONT_SIZE * scaleFactor)
  $(".nScaleTransform").css(transformCss("scale(#{scaleFactor})"))

Meteor.startup ->
  iPhoneHideNavbar()
  $("body").on "orientationchange", ->
    iPhoneHideNavbar()
  $("body").addClass(noughts.getInterfaceMode())
  #scaleInterface()