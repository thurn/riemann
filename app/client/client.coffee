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

showInviteDialog = (inviteCallback) -> FB.ui
  method: 'apprequests',
  title: 'Select an opponent',
  filters: ['app_non_users', 'app_users'],
  max_recipients: 1,
  message: 'Want to play some Noughts?', inviteCallback

PlayScreen = me.ScreenObject.extend
  getTile_: (row, column) ->
    @mainLayer_.getTile(column * TILE_SIZE, row * TILE_SIZE)

  monitorGameState_: ->
    Meteor.autorun =>
      game = noughts.Games.findOne {_id: Session.get("gameId")}
      console.log ">>>>> re-rendering"
      return if not game
      for move in game.moves
        tile = @getTile_(move.row, move.column)
        image = if move.isX then @xImg_ else @oImg_
        sprite = new me.SpriteObject(
            move.column * TILE_SIZE, move.row * TILE_SIZE, image)
        me.game.add(sprite, SPRITE_Z_INDEX)
        me.game.sort()
        me.input.releaseMouseEvent('mousedown', tile)

  handleClick_: (tile) ->
    game = noughts.Games.findOne {_id: Session.get("gameId")}
    if game and game.currentPlayer == noughts.userId
      isXPlayer = game.currentPlayer == game.xPlayer
      image = if isXPlayer then @xImg_ else @oImg_
      sprite = new me.SpriteObject(tile.pos.x, tile.pos.y, image)
      me.game.add(sprite, SPRITE_Z_INDEX)
      me.game.sort()
      noughts.Games.update {_id: Session.get("gameId")},
        $set:
          currentPlayer: if isXPlayer then game.oPlayer else game.xPlayer
        $push: # melon.js is basically totally insane about .row and .col...
          moves: {row: tile.col, column: tile.row, isX: isXPlayer}

  onResetEvent: () ->
    $('.noughtsNewGame').css('visibility', 'hidden')
    @xImg_ = me.loader.getImage('x')
    @oImg_ = me.loader.getImage('o')

    me.levelDirector.loadLevel('tilemap')
    @mainLayer_ = me.game.currentLevel.getLayerByName('mainLayer')
    for column in [0..2]
      for row in [0..2]
        tile = @getTile_(row, column)
        me.input.registerMouseEvent('mousedown', tile,
            _.bind(@handleClick_, this, tile))
    @monitorGameState_()

handleNewGameClick = ->
  gameId = noughts.Games.insert
    xPlayer: noughts.userId
    currentPlayer: noughts.userId
    moves: []
  showInviteDialog (inviteResponse) ->
    return if not inviteResponse
    invitedUser = inviteResponse.to[0]
    noughts.Games.update {_id: gameId}
      $set:
        oPlayer: invitedUser
        requestId: inviteResponse.request
    Session.set("gameId", gameId)
    me.state.change(me.state.PLAY)

TitleScreen = me.ScreenObject.extend
  init: ->
    @parent(true)
    @title_ = me.loader.getImage('title')
    $('.noughtsNewGame').on('click', handleNewGameClick)

  draw: (context) ->
    $('.noughtsNewGame').css('visibility', 'visible')
    context.drawImage(@title_, 0, 0)

onload = ->
  initialized = me.video.init('jsapp', 384, 384)
  if not initialized
    alert('Sorry, your browser doesn\'t support HTML 5 canvas!')
    return
  me.loader.onload = noughts.runOnSecondCall
  me.loader.preload(gameResources)

Meteor.startup(onload)

# In order to wait for both Meteor and the Facebook SDK, this function
# does nothing when first called and then proceeds on the second call.
numCalls = 0
noughts.runOnSecondCall = ->
  return numCalls++ if numCalls == 0
  me.state.set(me.state.PLAY, new PlayScreen())
  me.state.set(me.state.MENU, new TitleScreen())
  requestIds = $.url().param('request_ids')?.split(',')
  if requestIds
    for requestId in requestIds
      fullId = "#{requestId}_#{noughts.userId}"
      game = noughts.Games.findOne {requestId: requestId}
      FB.api fullId, 'delete', (response) ->
        if response != true
          throw new Error('Request delete failed: ' + response.error.message)
        if game
          noughts.Games.update({_id: game._id}, {$unset: {requestId: ''}})
    if game
      # TODO(dthurn) do something smarter with multiple request_ids than loading
      # the game for the last one.
      Session.set("gameId", game._id)
      return me.state.change(me.state.PLAY)
  me.state.change(me.state.MENU)
