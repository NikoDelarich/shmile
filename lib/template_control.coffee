assert = require('assert')

LandscapeTwoByTwo = require("./image_compositor")
PortraitOneByFour = require("./double_image_compositor")
LandscapeOneByThree = require("./landscape_3x8_compositor")

#template = new Template({overlayImage: "/images/landscape3x8.png", photoView: 'LandscapeOneByThree', compositor: new Landscape3x8Compositor(), printerEnabled: true, printer: 'abc'})
# template = new Template({overlayImage: "/images/img_photobooth.png", photoView: 'PortraitOneByFour', compositor: new DoubleImageCompositor(), printerEnabled:true, printer: '-d dye -o fit-to-page -o PageSize=w288h432-div2 -o StpLaminate=Matte'})
# template = new Template({overlayImage: "/images/overlay.png", photoView: 'LandscapeTwoByTwo', compositor: new ImageCompositor(), printer: '-d dye -o fit-to-page -o PageSize=w288h432 -o StpLaminate=Matte'})


Template = require("./template")

class TemplateControl
  # TODO: Use eval?
  compositors:
    PortraitOneByFour: PortraitOneByFour
    LandscapeOneByThree: LandscapeOneByThree
    LandscapeTwoByTwo: LandscapeTwoByTwo

  constructor:  (@name) ->
    @availableTemplates = Object.keys(@compositors)
    this.setTemplate(@name)

  setTemplate: (name) ->
    assert(name in @availableTemplates, "unknown template #{name}")

    overlay = "/images/#{name}.png"

    @template = new Template({
      overlayImage: overlay,
      photoView: name,
      compositor: new (this.compositors[name])})

    @printerEnabled = !!@template.printerEnabled
    @printer = @template.printer
    @compositor = @template.compositor
    @overlayImage = @template.overlayImage

module.exports = TemplateControl
