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

  constructor:  (templateName) ->
    @templates = Template.getTemplates()
    @availableTemplates = Object.keys(@templates)
    this.setTemplate(templateName)

  setTemplate: (name) ->
    assert(name in @availableTemplates, "unknown template #{name}")

    tt = @templates[name]

    @template = new Template({
      overlayImage: tt.overlayImage,
      photoView: tt.photoView,
      compositor: new (this.compositors[name]),
      pageLayout: tt.pageLayout})

module.exports = TemplateControl
