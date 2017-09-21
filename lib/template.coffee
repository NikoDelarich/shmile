ImageCompositor = require("./image_compositor")
fs = require('fs')

class Template

  @templates = JSON.parse(fs.readFileSync("templates.json", 'utf8'))

  defaults:
    # FIXME: move out of here
    printerEnabled: false
    # FIXME: move out of here - kinda, we need to keep the page options
    printer: ""
    overlayImage: ""
    photoView: ""
    photosTotal: 4
    compositor: new ImageCompositor()

  constructor: (options = {}) ->
    @printerEnabled = options.printerEnabled ? @defaults.printerEnabled
    @printer = options.printer ? @defaults.printer
    @overlayImage = options.overlayImage ? @defaults.overlayImage
    @photoView = options.photoView ? @defaults.photoView
    @photosTotal = options.photosTotal ? @defaults.photosTotal
    @compositor = options.compositor ? @defaults.compositor


  @getTemplates: ->
    @templates

module.exports = Template
