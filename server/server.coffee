Meteor.publish "myGames", ->
  noughts.Games.find
    $or: [{xPlayer: this.userId}, {oPlayer: this.userId}]

Meteor.startup ->
  return unless Meteor.settings["test"]
  require = __meteor_bootstrap__.require
  require("coffee-script")
  fs = require("fs")
  path = require("path")
  Mocha = require("mocha")

  mocha = new Mocha()
  files = fs.readdirSync("tests")
  basePath = fs.realpathSync("tests")
  for file in files
    continue unless file.match(/\.coffee$/) or file.match(/\.js$/)
    continue if file[0] == "."
    filePath = path.join(basePath, file)
    continue unless fs.statSync(filePath).isFile()
    mocha.addFile(filePath)
  mocha.run()
