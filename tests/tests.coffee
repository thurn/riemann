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
  fakeGameId = noughts.Games.insert
    xPlayer: XPLAYER
    oPlayer: OPLAYER
    currentPlayer: XPLAYER
    moves: []

after ->
  noughts.Games = oldGames
  Meteor.userId = oldUserId

itShould = (desc, fn) ->
  it desc, (done) -> (Fiber -> fn(done)).run()

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
  itShould "not mutate if called with an invalid ID", (done) ->
    observer = errorOnMutateObserver(noughts.Games)
    Meteor.call("performMoveIfLegal", "invalidId", 1, 1)
    observer.stop()
    done()