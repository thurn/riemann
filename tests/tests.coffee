chai = require("chai")
assert = chai.assert
should = chai.should()

XPLAYER = "123"
OPLAYER = "456"

fakeGameId = oldGames = Games = oldUserId = null

before ->
  oldGames = noughts.Games
  oldUserId = Meteor.userId
  Meteor.userId = () -> XPLAYER
  oldGames = noughts.Games
  noughts.Games = new Meteor.Collection(null)

after ->
  noughts.Games = oldGames
  Meteor.userId = oldUserId

beforeEach ->
  fakeGameId = noughts.Games.insert
    xPlayer: XPLAYER
    oPlayer: OPLAYER
    currentPlayer: XPLAYER
    moves: []

afterEach ->
  noughts.Games.remove fakeGameId

itShould = (desc, fn) ->
  it(("should " + desc), (done) -> (Fiber ->
    fn()
    done()).run())

fakeGame = (moves) ->
  {xPlayer: XPLAYER, oPlayer: OPLAYER, currentPlayer: XPLAYER, moves: moves}

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

callWithErrorOnMutate = (fn) ->
  observer = errorOnMutateObserver(noughts.Games)
  fn()
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

describe "performMoveIfLegal", ->
  itShould "not mutate if called with an invalid ID", ->
    callWithErrorOnMutate ->
      Meteor.call("performMoveIfLegal", "invalidId", 1, 1)

  itShould "not mutate if the current player isn't the calling  user", ->
    noughts.Games.update fakeGameId, {$set: {currentPlayer: OPLAYER}}
    callWithErrorOnMutate ->
      Meteor.call("performMoveIfLegal", fakeGameId, 1, 1)

  itShould "not mutate if called with a space that's taken", ->
    noughts.Games.update fakeGameId,
      $push: {moves: {column: 1, row: 1, isX: true}}
    callWithErrorOnMutate ->
      Meteor.call("performMoveIfLegal", fakeGameId, 1, 1)

  itShould "execute a valid move if it's passed one", ->
    Meteor.call("performMoveIfLegal", fakeGameId, 1, 1)
    game = noughts.Games.findOne fakeGameId
    game.currentPlayer.should.equal(OPLAYER)
    game.xPlayer.should.equal(XPLAYER)
    game.oPlayer.should.equal(OPLAYER)
    game.moves.should.have.length(1)
    move = game.moves[0]
    move.column.should.equal(1)
    move.row.should.equal(1)
    move.isX.should.be.true
