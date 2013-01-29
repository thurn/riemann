# Project Riemann client interface

gameResources = [{
  name: "tileset"
  type: "image"
  src: "/tilemaps/tileset.png"
}, {
  name: "tilemap"
  type: "tmx"
  src: "/tilemaps/tilemap.tmx"
}]

onload = ->
  initialized = me.video.init('jsapp', 384, 384)
  if not initialized
    alert("Sorry, your browser doesn't support HTML 5 canvas!")
    return
  me.audio.init("mp3,ogg")
  me.loader.onload = loaded
  me.loader.preload(gameResources)
  me.state.change(me.state.LOADING)

loaded = ->
  me.state.set(me.state.PLAY, new PlayScreen())
  me.state.change(me.state.PLAY);

PlayScreen = me.ScreenObject.extend
  onResetEvent: ->
    me.levelDirector.loadLevel("tilemap")

Meteor.startup(onload)