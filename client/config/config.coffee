###
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty. You should have
# received a copy of the CC0 Public Domain Dedication along with this software.
# If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
###

isLocalhost = window.location.href.indexOf("localhost") != -1
devUrl = "http://apps.facebook.com/noughts-dev/"
prodUrl = "https://apps.facebook.com/noughts/"

noughts.ClientConfig = {}

noughts.ClientConfig = {
  isLocalhost: isLocalhost
  appId: if isLocalhost then 143448845819008 else 419772734774541
  appUrl: if isLocalhost then devUrl else prodUrl
}
