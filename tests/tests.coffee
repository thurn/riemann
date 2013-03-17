###
To the extent possible under law, the author(s) have dedicated all copyright
and related and neighboring rights to this software to the public domain
worldwide. This software is distributed without any warranty. You should have
received a copy of the CC0 Public Domain Dedication along with this software.
If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
###

chai = require("chai")
expect = chai.expect
should = chai.should()
nock = require("nock")

XPLAYER = "123"
OPLAYER = "456"
REQUEST_ID = "789"

fakeGameId = realGamesCollection = Games = realUserIdFn = null

before ->
  realUserIdFn = Meteor.userId
  Meteor.userId = -> XPLAYER
  realGamesCollection = noughts.Games
  noughts.Games = new Meteor.Collection(null)

after ->
  noughts.Games = realGamesCollection
  Meteor.userId = realUserIdFn

beforeEach ->
  fakeGameId = noughts.Games.insert
    xPlayer: XPLAYER
    oPlayer: OPLAYER
    currentPlayer: XPLAYER
    moves: []

afterEach ->
  noughts.Games.remove fakeGameId

# A version of mocha's "it" function which wraps the test body in a Fiber.
itShould = (desc, fn) ->
  it(("should " + desc), (done) -> (Fiber ->
    fn()
    done()).run())

# Makes a javascript object with the provided moves that resembles a real
# Game collect object.
fakeGame = (moves) ->
  {xPlayer: XPLAYER, oPlayer: OPLAYER, currentPlayer: XPLAYER, moves: moves}

# Creates a new Meteor observer which throws an Error whenever somebody mutates
# the provided collection.
errorOnMutateObserver = (collection) ->
  collection.find({}).observe
    _suppress_initial: true
    added: (document) ->
      throw new Error("Unexpected addition of\n" + JSON.stringify(document))
    changed: (newDocument, oldDocument) ->
      throw new Error("Unexpected change from\n" + JSON.stringify(oldDocument) +
          "\nto\n" + JSON.stringify(newDocument))
    removed: (document) ->
      throw new Error("Unexpected removal of\n" + JSON.stringify(document))

# Calls fn with no arguments, throws an Error if it attempts to mutate the
# Games collection
callWithErrorOnMutate = (fn) ->
  observer = errorOnMutateObserver(noughts.Games)
  try
    fn()
  finally
    observer.stop()

# Calls fn with no arguments and asserts that it will throw BadRequestError.
# Throws an Error if it attempts to mutate the Games collection
expectBadRequestAndNoMutate = (fn) ->
  observer = errorOnMutateObserver(noughts.Games)
  try
    fn.should.throw(noughts.BadRequestError)
  finally
    observer.stop()

describe "noughts.checkForVictory", ->
  it "should be false for a game with no moves", ->
    result = noughts.checkForVictory(fakeGame([]))
    result.should.be.false
  it "should be false for one move", ->
    result = noughts.checkForVictory(fakeGame([{column: 1, row: 1, isX: true}]))
    result.should.be.false
  it "should be false for three moves", ->
    result = noughts.checkForVictory fakeGame [
        {column: 0, row: 0, isX: true}
        {column: 2, row: 0, isX: false}
        {column: 2, row: 2, isX: true}
    ]
    result.should.be.false
  it "should be false for a line of different symbols", ->
    result = noughts.checkForVictory fakeGame [
        {column: 0, row: 0, isX: true}
        {column: 0, row: 1, isX: false}
        {column: 0, row: 2, isX: true}
    ]
    result.should.be.false
  it "should return XPLAYER for a column of Xs", ->
    result = noughts.checkForVictory fakeGame [
        {column: 0, row: 0, isX: true}
        {column: 0, row: 1, isX: true}
        {column: 0, row: 2, isX: true}
        {column: 2, row: 2, isX: false}
        {column: 2, row: 0, isX: false}
    ]
    result.should.equal XPLAYER
  it "should return OPLAYER for a diagonal of Os", ->
    result = noughts.checkForVictory fakeGame [
        {column: 0, row: 0, isX: false}
        {column: 1, row: 1, isX: false}
        {column: 2, row: 2, isX: false}
        {column: 0, row: 1, isX: true}
        {column: 0, row: 2, isX: true}
        {column: 1, row: 2, isX: true}
    ]
    result.should.equal OPLAYER

describe "noughts.isDraw", ->
  it "should be false for a game with no moves", ->
    result = noughts.isDraw(fakeGame([]))
    result.should.be.false
  it "should be false for a game with one moves", ->
    result = noughts.isDraw(fakeGame([{column: 1, row: 1, isX: true}]))
    result.should.be.false
  it "should be false for a game with eight moves", ->
    result = noughts.isDraw fakeGame [
        {column: 0, row: 0, isX: true}
        {column: 0, row: 1, isX: false}
        {column: 0, row: 2, isX: true}
        {column: 1, row: 0, isX: false}
        {column: 1, row: 1, isX: true}
        {column: 1, row: 2, isX: false}
        {column: 2, row: 0, isX: true}
        {column: 2, row: 1, isX: false}
    ]
    result.should.be.false
  it "should be true for a game with nine moves", ->
    result = noughts.isDraw fakeGame [
        {column: 0, row: 0, isX: true}
        {column: 0, row: 1, isX: false}
        {column: 0, row: 2, isX: true}
        {column: 1, row: 0, isX: false}
        {column: 1, row: 1, isX: true}
        {column: 1, row: 2, isX: false}
        {column: 2, row: 0, isX: true}
        {column: 2, row: 1, isX: false}
        {column: 2, row: 2, isX: true}
    ]
    result.should.be.true

describe "authenticate", ->
  itShould "fail if the GET to facebook returns an error", ->
    nock("https://graph.facebook.com", {allowUnmocked: true}).
        get("/me?fields=id&access_token=accessToken").
        reply(404, {})
    fn = (-> Meteor.call("authenticate", OPLAYER, "accessToken"))
    fn.should.throw(Error)
    Meteor.userId().should.equal(XPLAYER)

  itShould "fail if facebook returns the wrong user ID", ->
    nock("https://graph.facebook.com", {allowUnmocked: true}).
        get("/me?fields=id&access_token=accessToken").
        reply(200, {id: XPLAYER})
    fn = (-> Meteor.call("authenticate", OPLAYER, "accessToken"))
    fn.should.throw(noughts.BadRequestError)
    Meteor.userId().should.equal(XPLAYER)

  # itShould "correctly change the user ID if facebook validates it"
  # This is currently not possible to easily test here because Meteor
  # rejects calls to setUserId which are initiated by server-side code

describe "performMoveIfLegal", ->
  itShould "not work if called with an invalid ID", ->
    expectBadRequestAndNoMutate ->
      Meteor.call("performMoveIfLegal", "invalidId", 1, 1)

  itShould "not work if the current player isn't the calling  user", ->
    noughts.Games.update fakeGameId, {$set: {currentPlayer: OPLAYER}}
    expectBadRequestAndNoMutate ->
      Meteor.call("performMoveIfLegal", fakeGameId, 1, 1)

  itShould "not mutate if called with a space that's taken", ->
    noughts.Games.update fakeGameId,
      $push: {moves: {column: 1, row: 1, isX: true}}
    callWithErrorOnMutate ->
      Meteor.call("performMoveIfLegal", fakeGameId, 1, 1)

  itShould "execute a valid move if it's passed one", ->
    Meteor.call("performMoveIfLegal", fakeGameId, 1, 1)
    game = noughts.Games.findOne(fakeGameId)
    game.currentPlayer.should.equal(OPLAYER)
    game.xPlayer.should.equal(XPLAYER)
    game.oPlayer.should.equal(OPLAYER)
    game.moves.should.have.length(1)
    move = game.moves[0]
    move.column.should.equal(1)
    move.row.should.equal(1)
    move.isX.should.be.true

describe "newGame", ->
  itShould "not work if called with an invalid ID", ->
    expectBadRequestAndNoMutate ->
      Meteor.call("newGame", "invalidId")

  itShould "create a new game if called with a valid ID", ->
    gameId = Meteor.call("newGame", XPLAYER)
    game = noughts.Games.findOne(gameId)
    game.xPlayer.should.equal(XPLAYER)
    game.currentPlayer.should.equal(XPLAYER)
    game.moves.should.have.length(0)
    expect(game.oPlayer).to.be.undefined

describe "inviteOpponent", ->
  itShould "not work if the caller isn't the game's current player", ->
    noughts.Games.update fakeGameId,
      $set: {currentPlayer: OPLAYER}
    expectBadRequestAndNoMutate ->
      Meteor.call("inviteOpponent", fakeGameId, OPLAYER, REQUEST_ID)

  itShould "not work if the game already has an opponent", ->
    expectBadRequestAndNoMutate ->
      Meteor.call("inviteOpponent", fakeGameId, OPLAYER, REQUEST_ID)

  itShould "not work for an invalid game ID", ->
    expectBadRequestAndNoMutate ->
      Meteor.call("inviteOpponent", "invalidGameId", OPLAYER, REQUEST_ID)

  itShould "add an opponent to the game", ->
    gameId = Meteor.call("newGame", XPLAYER)
    Meteor.call("inviteOpponent", gameId, OPLAYER, REQUEST_ID)
    game = noughts.Games.findOne(gameId)
    game.xPlayer.should.equal(XPLAYER)
    game.currentPlayer.should.equal(XPLAYER)
    game.moves.should.have.length(0)
    game.oPlayer.should.equal(OPLAYER)
    game.requestId.should.equal(REQUEST_ID)
