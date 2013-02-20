inviteCallback = (response) ->
  console.log response

facebookLoaded = () ->
  $('.noughtsSendInvite').live('click', onInviteClick)

onInviteClick = () ->
  FB.ui {
      method: 'apprequests',
      title: 'Noughts Invitation',
      message: 'Would you like to play Noughts?',
      filters: ['app_non_users', 'app_users']
    }, inviteCallback

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
        $(".fb-login-button").show();
      else
        facebookLoaded()

  ref = document.getElementsByTagName('script')[0]
  if document.getElementById('facebook-jssdk')
    return
  js = document.createElement('script')
  js.id = 'facebook-jssdk'
  js.async = true;
  js.src = '//connect.facebook.net/en_US/all.js'
  ref.parentNode.insertBefore(js, ref);
