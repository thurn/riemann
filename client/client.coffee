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

# Tile square size in pixels
TILE_SIZE = 128

PlayScreen = me.ScreenObject.extend
  handleClick_: (tile) ->
    console.dir(tile.pos)

  onResetEvent: ->
    me.levelDirector.loadLevel("tilemap")
    this.mainLayer_ = me.game.currentLevel.getLayerByName("mainLayer")
    for column in [0..2]
      for row in [0..2]
        tile = this.mainLayer_.getTile(column * TILE_SIZE, row * TILE_SIZE)
        me.input.registerMouseEvent('mousedown', tile,
            _.bind(this.handleClick_, this, tile))

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

Meteor.startup(onload)