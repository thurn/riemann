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

useMobileStyle = ->
  $(window).width() < 600 and $(window).height() < 400

computeScaleFactor = ->
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
    return 1.0 # Full size, scaling not required
  else if width >= 600 and height >= 400 # desktop style
    return computeScale(1200, 800)
  else if height >= 356 # mobile portrait style
    return computeScale(320, 356)
  else # mobile landscape style
    return computeScale(480, 268)

CONTAINER_HEIGHT = 768
CONTAINER_WIDTH = 1064
MAIN_WIDTH = 640
MAIN_HEIGHT = CONTAINER_HEIGHT
NAVIGATION_WIDTH = 400
NAVIGATION_HEIGHT = CONTAINER_HEIGHT

scaleInterface = ->
  scale = computeScaleFactor()
  Session.set("scaleFactor", scale)
  unless useMobileStyle()
    $(".nContainer").css(noughts.centeredBlockCss(scale, CONTAINER_WIDTH,
        CONTAINER_HEIGHT, "fixed"))
    $(".nMain").css(widthHeightCss(scale, MAIN_WIDTH, MAIN_HEIGHT))
    mainLeft = NAVIGATION_WIDTH + (CONTAINER_WIDTH - NAVIGATION_WIDTH - MAIN_WIDTH)
    $(".nMain").css({left: "#{mainLeft * scale}px"})
    $(".nNavigation").css(widthHeightCss(scale, NAVIGATION_WIDTH,
        NAVIGATION_HEIGHT))
    $(".nGame").css(transformCss("scale(#{scale})"))
    $(".nLogoContainer").css(transformCss("scale(#{scale})"))
    $(".nNotification").css({width: MAIN_WIDTH * scale})
    $(".nNotification").css(transformCss("scale(#{scale})"))

Meteor.startup ->
  iPhoneHideNavbar()
  $("body").on "orientationchange", ->
    iPhoneHideNavbar()
  scaleInterface()