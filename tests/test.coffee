mocha.setup({globals: ['FB']})
chai.should();

describe "Addition", ->
  it "equals 4", ->
    result = 2 + 2
    result.should.equal(4)
