mocha.setup({globals: ['FB']})
chai.should();

describe "Addition", ->
  it "equals 6", ->
    result = 3 + 3
    result.should.equal(6)
