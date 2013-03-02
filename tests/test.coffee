mocha.setup({globals: ['FB']})
chai.should();

describe "Addition", ->
  it "equals 4", ->
    result = 3 + 1
    result.should.equal(4)
