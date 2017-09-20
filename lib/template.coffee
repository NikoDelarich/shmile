ImageCompositor = require("./image_compositor")

class Template

  defaults:
    printerEnabled: false
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


module.exports = Template
