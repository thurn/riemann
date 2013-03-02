mocha.setup({globals: ['FB']})
should = chai.should();

describe "noughts.checkForVictory", ->
  it "should be false for an empty input", ->
    result = noughts.checkForVictory({})
    result.should.be.false;
