###
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty. You should have
# received a copy of the CC0 Public Domain Dedication along with this software.
# If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
###

isLocalhost = window.location.href.indexOf("localhost") != -1
# TODO(dthurn): Use Meteor.rootUrl() here
devUrl = "http://localhost:3000/"
prodUrl = "https://apps.facebook.com/noughts/"

noughts.ClientConfig = {}

noughts.ClientConfig = {
  isLocalhost: isLocalhost
  appId: if isLocalhost then 143448845819008 else 419772734774541
  appUrl: if isLocalhost then devUrl else prodUrl
}

noughts.util = {}

noughts.util.isMobile = -> $("html").hasClass("nMobile")

noughts.util.isTouch = "ontouchstart" of window

noughts.util.isAndroid = /Android/.test(navigator.userAgent)

noughts.util.isiOS = /iP(ad|hone|od)/.test(navigator.userAgent)

noughts.util.isiOSPhone = /iP(hone|od)/.test(navigator.userAgent)

noughts.util.isChrome = /Chrome\/[0-9]+/.test(navigator.userAgent)

noughts.util.inIframe = window != window.top

# Checks if the device is known to have a reasonable implementation of the
# "click" event (no 300ms delay)
goodClicks = ->
	unless noughts.util.isTouch
    return true
  # Chrome does it right with user-scalable=no
  return true if noughts.util.isChrome
  # Most other touch devices do it wrong
	return false

noughts.util.clickString = if goodClicks() then "click" else "tap"

noughts.util.clickEvent = if goodClicks() then "click" else "touchend"
