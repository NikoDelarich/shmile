ImageCompositor = require("./image_compositor")
fs = require('fs')

class Template

  @templates = JSON.parse(fs.readFileSync("templates.json", 'utf8'))

  defaults:
    pageLayout: ""
    # FIXME: remove this
    overlayImage: ""
    photoView: ""
    compositor: null

  constructor: (options = {}) ->
    @printerEnabled = options.printerEnabled ? @defaults.printerEnabled
    @pageLayout = options.pageLayout ? @defaults.pageLayout
    @overlayImage = options.overlayImage ? @defaults.overlayImage
    @photoView = options.photoView ? @defaults.photoView
    @photosTotal = options.photosTotal ? @defaults.photosTotal
    @compositor = options.compositor ? @defaults.compositor

  @getTemplates: ->
    @templates

module.exports = Template
