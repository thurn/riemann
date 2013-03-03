###
# Tests for model.coffee
###

mocha.setup({globals: ['FB']})
should = chai.should();

XPLAYER = 123
OPLAYER = 456

fakeGame = (moves) ->
  {xPlayer: XPLAYER, oPlayer: OPLAYER, currentPlayer: XPLAYER, moves: moves}

FakeCollection = ->
  this.localCollection_ = new LocalCollection()
  this

FakeCollection.prototype.insert = (doc, callback) ->
  unless _.has(doc, '_id')
    doc._id = Random.id()
  try
    this.localCollection_.insert(doc)
  catch error
    if callback
      callback(error)
    else
      throw error
  finally
    if callback
      callback(undefined, doc._id)
    else
      return doc._id

FakeCollection.prototype.findOne = (selector, options) ->
    this.localCollection_.findOne(selector, options)

FakeCollection.prototype.update = (selector, modifier, options, callback) ->
  try
    this.localCollection_.update(selector, modifier, options)
  catch error
    if callback
      callback(error)
    else
      throw error
  finally
    if callback
      callback()

FakeCollection.prototype.find = (selector, options) ->
  this.localCollection_.find(selector, optoins)

newGame = (callback) ->
  noughts.Games.insert
    xPlayer: XPLAYER
    currentPlayer: XPLAYER
    oPlayer: OPLAYER
    moves: []
    testing: true, (err, result) ->
      if err then throw err
      callback result

before (done) ->
  noughts.Games = new FakeCollection()
  Meteor.call("setUserId", XPLAYER, done)

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
  it "should do nothing for a missing game ID", (done) ->
    newGame (gameId) ->
      Meteor.call "performMoveIfLegal", gameId, 1, 1, (err) ->
        if err then throw err
        debugger
        done()