doc = document.documentElement
navClass = 'nNavOpen'

closeNav = (event) ->
  event.stopPropagation()
  $(doc).removeClass(navClass);
  $(".nTopHeader, .nMain").off("click")
  $(".nMenuToggleButton").on("click", openNav)

openNav = (event) ->
  event.stopPropagation()
  $(doc).addClass(navClass)
  $(".nMenuToggleButton").off("click")
  $(".nTopHeader, .nMain").on("click", closeNav)

Meteor.startup ->
  $(".nMenuToggleButton").on("click", openNav)

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

# Possible UI modes
noughts.Mode =
  DESKTOP: "nDesktopMode"
  PORTRAIT: "nPortraitMode"
  LANDSCAPE: "nLandscapeMode"

# Computes which of the three UI modes (Desktop, Portrait, Landscape) should be
# used, based on the current window height and width.
getInterfaceMode = ->
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
computeScaleFactor = ->
  mode = getInterfaceMode()
  {width: width, height: height} = widthAndHeight()

  # Computes the ratio of whichever of the current width and height are
  # further from the provided targets.
  computeScale = (targetWidth, targetHeight) ->
    heightRatio = height / targetHeight
    widthRatio = width / targetWidth
    if heightRatio > widthRatio then widthRatio else heightRatio

  return 1 if width > 1200 and height > 768 # Full size, no scaling required

  result = switch mode
    when noughts.Mode.DESKTOP then computeScale(1200, 768)
    when noughts.Mode.LANDSCAPE then computeScale(268, 234)
    when noughts.Mode.PORTRAIT then computeScale(320, 366)
  Session.set("scaleFactor", result)
  return result

# Returns an array of functions for scaling DOM elements. Each function takes a
# scale as a parameter, and then applies this scale to a particular CSS
# property. The functions apply to most of the display-able DOM elements.
getZoomFunctions = ->
  functions = []

  # Returns a function which will scale the provided CSS property on the
  # provided element by a certain scaling factor.
  scaleProperty = (element, property) ->
    propertyString = element.css(property)
    value = parseFloat(propertyString)
    return if isNaN(value) or value == 0
    functions.push((scale) -> element.css(property, value * scale))

  properties = ["height", "width", "margin-top", "margin-right",
      "margin-bottom", "margin-left", "padding-top", "padding-right",
      "padding-bottom", "padding-left", "font-size"]

  $("div,nav,header,button,img").each ->
    for property in properties
      scaleProperty($(this), property)

  return functions

zoomFunctions = null
# Using the value in 'zoomFunctions', an array of zoom functions as returned by
# getZoomeFunctions, invoke each zoom function with the provided scaling factor.
zoom = (scaleFactor) ->
  return unless zoomFunctions
  for zoomFunction in zoomFunctions
    zoomFunction(scaleFactor)

Meteor.startup ->
  iPhoneHideNavbar()
  $("body").on "orientationchange", ->
    iPhoneHideNavbar()
  $("body").addClass(getInterfaceMode())

  $(window).on "load", ->
    zoomFunctions = getZoomFunctions()
    zoom(computeScaleFactor())

  rescale = null
  $(window).on "resize", ->
    clearTimeout(rescale)
    rescale = setTimeout((-> zoom(computeScaleFactor())), 100)
