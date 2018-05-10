fs = require('fs')

class ShmileConfig
  defaults:
    configFile: "shmile_config.json"
    templatesFile: "templates.json"
    # TODO: make configurable
    printerCmdLine: "lp -o fit-to-page"
    printFinishCmd: "-o StpLaminate="
    printDefaultFinish: "Matte"

  constructor: (@opts=null) ->
    @opts = @defaults if @opts is null
    this.read()

  read: ->
    @config = JSON.parse(fs.readFileSync(@opts.configFile, 'utf8'))
    if !@config.print_finish? then @config.print_finish = @defaults.printDefaultFinish
    @currentTemplate = @config.current_template
    @config

  write: ->
    fs.writeFileSync(@opts.configFile, JSON.stringify(@config, null, 2))
    this.read()

  setTemplate: (template) ->
    @config.current_template = template
    this.write()
    template

  get: (property) ->
    @config[property]


module.exports = ShmileConfig
