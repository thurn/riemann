###
# Tests for model.coffee
###

mocha.setup({globals: ['FB']})
should = chai.should();

XPLAYER = 123
OPLAYER = 456

fakeGame = (moves) ->
  {xPlayer: XPLAYER, oPlayer: OPLAYER, currentPlayer: XPLAYER, moves: moves}

newGame = (callback) ->
  noughts.Games.insert
    xPlayer: XPLAYER
    currentPlayer: XPLAYER
    oPlayer: OPLAYER
    moves: []
    testing: true, callback

errorOnChangeObserver = (collection) ->
  collection.find().observeChanges
      added: (id, fields) ->
        throw new Error("unexpected addition of ID " + id + " with fields " +
            fields)
      changed: (id, fields) ->
        throw new Error("unexpected mutation of ID " + id + " for fields " +
            fields)
      removed: (id) ->
        throw new Error("unexpected deletion of ID " + id)

before (done) ->
  Meteor.call "setUserId", XPLAYER, (err) ->
    if err then throw err
    Meteor.subscribe "myGames", ->
      done()

after (done) ->
  Meteor.call("clearTestGames", done)

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
  it "should not modify the database for a missing game ID", (done) ->
    observer = errorOnChangeObserver(noughts.Games)
    Meteor.call "performMoveIfLegal", "invalidId", 1, 1, (err) ->
      if err then throw err
      observer.stop()
      done()