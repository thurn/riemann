# Project Riemann client interface

gameResources = [{
  name: "tileset"
  type: "image"
  src: "/tilemaps/tileset.jpg"
}, {
  name: "x"
  type: "image"
  src: "/images/x.png"
}, {
  name: "o"
  type: "image"
  src: "/images/o.png"
}, {
  name: "tilemap"
  type: "tmx"
  src: "/tilemaps/tilemap.tmx"
}]

# Tile square size in pixels
TILE_SIZE = 128
SPRITE_Z_INDEX = 2

PlayScreen = me.ScreenObject.extend
  handleClick_: (tile) ->
    image = if this.xPlayerTurn_ then this.xImg_ else this.oImg_
    sprite = new me.SpriteObject(tile.pos.x, tile.pos.y, image)
    me.game.add(sprite, SPRITE_Z_INDEX)
    me.game.sort()
    this.xPlayerTurn_ = not this.xPlayerTurn_

  onResetEvent: ->
    this.xImg_ = me.loader.getImage("x")
    this.oImg_ = me.loader.getImage("o")
    this.xPlayerTurn_ = true # x player goes first

    me.levelDirector.loadLevel("tilemap")
    mainLayer = me.game.currentLevel.getLayerByName("mainLayer")
    for column in [0..2]
      for row in [0..2]
        tile = mainLayer.getTile(column * TILE_SIZE, row * TILE_SIZE)
        me.input.registerMouseEvent('mousedown', tile,
            _.bind(this.handleClick_, this, tile))

onload = ->
  initialized = me.video.init('jsapp', 384, 384)
  if not initialized
    alert("Sorry, your browser doesn't support HTML 5 canvas!")
    return
  me.loader.onload = loaded
  me.loader.preload(gameResources)

loaded = ->
  FB.getLoginStatus (response) ->
    if response.status == 'connected'
      me.state.set(me.state.PLAY, new PlayScreen())
      me.state.change(me.state.PLAY);
    else
      $(".fb-login-button").show();

Meteor.startup(onload)