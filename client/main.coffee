# normalize vendor prefixes
doc = document.documentElement

transform_prop = Modernizr.prefixed('transform')
transition_prop = Modernizr.prefixed('transition')
props =
  WebkitTransition: 'webkitTransitionEnd',
  MozTransition: 'transitionend',
  OTransition: 'oTransitionEnd otransitionend',
  msTransition: 'MSTransitionEnd',
  transition: 'transitionend'
transition_end = if props.hasOwnProperty(transition_prop) then props[transition_prop] else false

nav_open = false
nav_class = 'nNavOpen'

closeNavEnd = (e) ->
  if e and e.target == document.getElementsByClassName('nInnerWrap')[0]
    document.removeEventListener(transition_end, closeNavEnd, false)
  nav_open = false

closeNav = ->
  if (nav_open)
      # close navigation after transition or immediately
      inner = document.getElementsByClassName('nInnerWrap')[0]
      if transition_end and transition_prop
        computedStyle = window.getComputedStyle(inner, '')
        duration = parseFloat(computedStyle[transition_prop + 'Duration'])
      else
        duration = 0
      if duration > 0
        document.addEventListener(transition_end, closeNavEnd, false)
      else
        closeNavEnd(null)
  $(doc).removeClass(nav_class);

openNav = ->
  if nav_open
    return
  $(doc).addClass(nav_class)
  nav_open = true

toggleNav = (e) ->
  if nav_open and $(doc).hasClass(nav_class)
    closeNav()
  else
    openNav()

  if e
    e.preventDefault();

callback = (e) ->
  if nav_open and !$(e.target).parents().add(e.target).hasClass('nNavigation')
    e.preventDefault()
    closeNav()

Meteor.startup ->
  # open nav with main "nav" button
  $(".nMenuToggleButton").on("click", toggleNav)

  # close nav by touching the partial off-screen content
  document.addEventListener('click', callback, true)
