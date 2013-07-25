###
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty. You should have
# received a copy of the CC0 Public Domain Dedication along with this software.
# If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
###

getOathUrl = (redirectPath) ->
  "https://www.facebook.com/dialog/oauth/?" +
  "client_id=#{noughts.ClientConfig.appId}" +
  "&redirect_uri=#{noughts.ClientConfig.appUrl}#{redirectPath}"

noughts.facebookDeferred = $.Deferred()

anonymousAuthenticate = ->
  # Otherwise, continue in the no-facebook state
  uuid = $.cookie("noughtsUuid")
  unless uuid
    uuid = Meteor.uuid()
    $.cookie("noughtsUuid", uuid, {expires: 7300})
  Meteor.call "anonymousAuthenticate", uuid, (err) ->
    noughts.facebookDeferred.resolve()

Template.facebook.created = ->
  window.fbAsyncInit = ->
    # Init the FB JS SDK
    FB.init
      appId: noughts.ClientConfig.appId, # App ID from the App Dashboard
      frictionlessRequests: true # Don't require authorization for each request
      channelUrl: noughts.ClientConfig.appUrl + '/fb/channel.html',
      status: true, # check the login status upon init?
      cookie: true, # set sessions cookies to allow your server to access the session?
      xfbml: true  # parse XFBML tags on this page?
    FB.getLoginStatus (response) ->
      if response.status == 'connected'
        # TODO(dthurn): If there's a pre-existing anonymous cookie, upgrade
        # all references to it to use the Facebook ID instead.
        accessToken = response.authResponse.accessToken
        fbid = response.authResponse.userID
        Meteor.call "facebookAuthenticate", fbid, accessToken, (err, profile) ->
          if err then throw err
          Session.set("facebookProfile", profile)
          noughts.facebookDeferred.resolve()
      else
        requestIds = $.url().param("request_ids")
        if requestIds
          # If there's a request ID, get user to auth with facebook
          top.location.href = getOathUrl("?request_ids=#{requestIds}")
        else
          anonymousAuthenticate()

  ref = document.getElementsByTagName('script')[0]
  if document.getElementById('facebook-jssdk')
    return
  js = document.createElement('script')
  js.id = 'facebook-jssdk'
  js.async = true
  js.src = '//connect.facebook.net/en_US/all.js'
  ref.parentNode.insertBefore(js, ref)

Meteor.startup ->
  # Add a timeout in case facebook loading fails
  facebookFallback = ->
    unless noughts.facebookDeferred.state() == "resolved"
      console.log("Facebook loading FAILED")
      anonymousAuthenticate()
      noughts.facebookDeferred.resolve()
  setTimeout(facebookFallback, 5000)