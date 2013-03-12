getOathUrl = (requestIds) ->
  return "https://www.facebook.com/dialog/oauth/?
    client_id=#{noughts.Config.appId}
    &scope=email
    &redirect_uri=#{noughts.Config.appUrl}?request_ids=#{requestIds}"

Template.facebook.created = ->
  window.fbAsyncInit = ->
    # Init the FB JS SDK
    FB.init
      appId: noughts.Config.appId, # App ID from the App Dashboard
      frictionlessRequests: true # Don't require authorization for each request
      channelUrl: noughts.Config.appUrl + '/fb/channel.html',
      status: true, # check the login status upon init?
      cookie: true, # set sessions cookies to allow your server to access the session?
      xfbml: true  # parse XFBML tags on this page?
    FB.getLoginStatus (response) ->
      if response.status != 'connected'
        requestIds = $.url().param("request_ids")
        top.location.href = getOathUrl(requestIds) # Redirect to facebook login
      else
        Meteor.call("setUserId", response.authResponse.userID)
        noughts.maybeInitialize()

  ref = document.getElementsByTagName('script')[0]
  if document.getElementById('facebook-jssdk')
    return
  js = document.createElement('script')
  js.id = 'facebook-jssdk'
  js.async = true;
  js.src = '//connect.facebook.net/en_US/all.js'
  ref.parentNode.insertBefore(js, ref);