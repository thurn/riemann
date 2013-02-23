# Project Riemann client interface

gameResources = [{
  name: 'tileset'
  type: 'image'
  src: '/tilemaps/tileset.jpg'
}, {
  name: 'x'
  type: 'image'
  src: '/images/x.png'
}, {
  name: 'o'
  type: 'image'
  src: '/images/o.png'
}, {
  name: 'title'
  type: 'image'
  src: '/images/title.png'
}, {
  name: 'tilemap'
  type: 'tmx'
  src: '/tilemaps/tilemap.tmx'
}]

# Tile square size in pixels
TILE_SIZE = 128
SPRITE_Z_INDEX = 2

showInviteDialog = (inviteCallback) -> FB.ui
  method: 'apprequests',
  title: 'Select an opponent',
  filters: ['app_non_users', 'app_users'],
  max_recipients: 1,
  message: 'Want to play some Noughts?', inviteCallback

PlayScreen = me.ScreenObject.extend
  handleClick_: (tile) ->
    image = if this.xPlayerTurn_ then this.xImg_ else this.oImg_
    sprite = new me.SpriteObject(tile.pos.x, tile.pos.y, image)
    me.game.add(sprite, SPRITE_Z_INDEX)
    me.game.sort()
    this.xPlayerTurn_ = not this.xPlayerTurn_

  onResetEvent: (requestId, invitedUser) ->
    console.log(invitedUser)
    $('.noughtsNewGame').css('visibility', 'hidden')
    this.xImg_ = me.loader.getImage('x')
    this.oImg_ = me.loader.getImage('o')
    this.xPlayerTurn_ = true # x player goes first

    me.levelDirector.loadLevel('tilemap')
    mainLayer = me.game.currentLevel.getLayerByName('mainLayer')
    for column in [0..2]
      for row in [0..2]
        tile = mainLayer.getTile(column * TILE_SIZE, row * TILE_SIZE)
        me.input.registerMouseEvent('mousedown', tile,
            _.bind(this.handleClick_, this, tile))

TitleScreen = me.ScreenObject.extend
  init: ->
    this.parent(true)
    this.title_ = me.loader.getImage('title')
    $('.noughtsNewGame').on 'click', ->
      showInviteDialog (inviteResponse) ->
        if inviteResponse
          requestId = inviteResponse.request
          invitedUser = inviteResponse.to[0]
          me.state.change(me.state.PLAY, requestId, invitedUser)

  draw: (context) ->
    $('.noughtsNewGame').css('visibility', 'visible')
    context.drawImage(this.title_, 0, 0)

onload = ->
  initialized = me.video.init('jsapp', 384, 384)
  if not initialized
    alert('Sorry, your browser doesn\'t support HTML 5 canvas!')
    return
  me.loader.onload = loaded
  me.loader.preload(gameResources)

loaded = ->
  me.state.set(me.state.PLAY, new PlayScreen())
  me.state.set(me.state.MENU, new TitleScreen())
  me.state.change(me.state.MENU)

Meteor.startup(onload)