Meteor.publish "myGames", ->
  noughts.Games.find
    $or: [{xPlayer: this.userId}, {oPlayer: this.userId}]

Meteor.startup ->
  return unless Meteor.settings["test"]
  require = __meteor_bootstrap__.require
  require("coffee-script")
  fs = require("fs")
  path = require("path")
  require("coffee-script")
  Mocha = require("mocha")

  mocha = new Mocha()
  files = fs.readdirSync("tests")
  basePath = fs.realpathSync("tests")
  for file in files
    continue unless file.match(/\.coffee$/) or file.match(/\.js$/)
    mocha.addFile(path.join(basePath, file))
  mocha.run()
