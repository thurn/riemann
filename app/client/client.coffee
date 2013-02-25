# Project Riemann client interface

gameResources = [
  {name: 'tileset', type: 'image', src: '/tilemaps/tileset.jpg'},
  {name: 'x', type: 'image', src: '/images/x.png'},
  {name: 'o', type: 'image', src: '/images/o.png'},
  {name: 'title', type: 'image', src: '/images/title.png'},
  {name: 'tilemap', type: 'tmx', src: '/tilemaps/tilemap.tmx'}
]

# Tile square size in pixels
TILE_SIZE = 128
SPRITE_Z_INDEX = 2

showInviteDialog = (gameId, inviteCallback) -> FB.ui
  method: 'apprequests',
  title: 'Select an opponent',
  filters: ['app_non_users', 'app_users'],
  max_recipients: 1,
  message: 'Want to play some Noughts?', inviteCallback

PlayScreen = me.ScreenObject.extend
  getTile_: (row, column) ->
    this.mainLayer_.getTile(column * TILE_SIZE, row * TILE_SIZE)

  renderGameState_: ->
    game = noughts.Games.findOne {_id: this.gameId_}
    for move in game.moves
      tile = this.getTile_(move.row, move.column)
      image = if move.isX then this.xImg_ else this.oImg_
      sprite = new me.SpriteObject(
          move.column * TILE_SIZE, move.row * TILE_SIZE, image)
      me.game.add(sprite, SPRITE_Z_INDEX)
      me.game.sort()
      me.input.releaseMouseEvent('mousedown', tile)

  handleClick_: (tile) ->
    game = noughts.Games.findOne {_id: this.gameId_}
    if game and game.currentPlayer == noughts.userId
      isXPlayer = game.currentPlayer == game.xPlayer
      image = if isXPlayer then this.xImg_ else this.oImg_
      sprite = new me.SpriteObject(tile.pos.x, tile.pos.y, image)
      me.game.add(sprite, SPRITE_Z_INDEX)
      me.game.sort()
      noughts.Games.update {_id: this.gameId_},
        $set:
          currentPlayer: if isXPlayer then game.oPlayer else game.xPlayer
        $push: # melon.js is basically totally insane about .row and .col...
          moves: {row: tile.col, column: tile.row, isX: isXPlayer}

  onResetEvent: (gameId) ->
    $('.noughtsNewGame').css('visibility', 'hidden')
    this.xImg_ = me.loader.getImage('x')
    this.oImg_ = me.loader.getImage('o')
    this.gameId_ = gameId

    me.levelDirector.loadLevel('tilemap')
    this.mainLayer_ = me.game.currentLevel.getLayerByName('mainLayer')
    for column in [0..2]
      for row in [0..2]
        tile = this.getTile_(row, column)
        me.input.registerMouseEvent('mousedown', tile,
            _.bind(this.handleClick_, this, tile))
    this.renderGameState_()

handleNewGameClick = ->
  gameId = noughts.Games.insert
    xPlayer: noughts.userId
    currentPlayer: noughts.userId
    moves: []
  showInviteDialog gameId, (inviteResponse) ->
    if inviteResponse
      invitedUser = inviteResponse.to[0]
      noughts.Games.update {_id: gameId}
        $set:
          oPlayer: invitedUser
          requestId: inviteResponse.request
      me.state.change(me.state.PLAY, gameId)

TitleScreen = me.ScreenObject.extend
  init: ->
    this.parent(true)
    this.title_ = me.loader.getImage('title')
    $('.noughtsNewGame').on('click', handleNewGameClick)

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
  requestId = $.url().param('request_ids')?.split(',')[0]
  if requestId
    game = noughts.Games.findOne {requestId: requestId}
    FB.api(requestId, 'delete')
    if game
      return me.state.change(me.state.PLAY, game._id)
  me.state.change(me.state.MENU)

Meteor.startup(onload)