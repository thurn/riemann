###
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty. You should have
# received a copy of the CC0 Public Domain Dedication along with this software.
# If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
###

Meteor.startup ->
  return unless Meteor.settings["test"]
  Npm.require("coffee-script")
  fs = Npm.require("fs")
  path = Npm.require("path")
  Mocha = Npm.require("mocha")

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
