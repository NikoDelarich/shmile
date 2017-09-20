assert = require('assert')

LandscapeTwoByTwo = require("./image_compositor")
PortraitOneByFour = require("./double_image_compositor")
LandscapeOneByThree = require("./landscape_3x8_compositor")
StripOneByThree = require("./strip_one_by_three_compositor")

Template = require("./template")

class TemplateControl
  # TODO: Use eval?
  compositors:
    PortraitOneByFour: PortraitOneByFour
    LandscapeOneByThree: LandscapeOneByThree
    LandscapeTwoByTwo: LandscapeTwoByTwo
    StripOneByThree: StripOneByThree

  constructor:  (shmileConfig) ->
    @availableTemplates = Object.keys(@compositors)
    @templates = shmileConfig.templates
    this.setTemplate(shmileConfig.currentTemplate)

  setTemplate: (name) ->
    assert(name in @availableTemplates, "unknown template #{name}")

    # overlay = "/images/#{name}.png"

    tt = @templates[name]
    # c = tt.compositor

    @template = new Template({
      overlayImage: tt.overlayImage,
      photoView: tt.photoView,
      compositor: new (this.compositors[name]),
      printerEnabled: tt.printerEnabled,
      printer: tt.printer})

    # @printerEnabled = !!@template.printerEnabled
    # @printer = @template.printer
    # @compositor = @template.compositor
    # @overlayImage = @template.overlayImage

module.exports = TemplateControl
