isLocalhost = window.location.href.indexOf("localhost") != -1
devUrl = "http://apps.facebook.com/noughts-dev/"
prodUrl = "https://apps.facebook.com/noughts/"

noughts.Config = {
  appId: if isLocalhost then 143448845819008 else 419772734774541
  appUrl: if isLocalhost then devUrl else prodUrl
}
