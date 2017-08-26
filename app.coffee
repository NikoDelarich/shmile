express = require "express"
jade = require "jade"
http = require "http"
fs = require "fs"
yaml = require "yaml"
dotenv = require "dotenv"
exec = require("child_process").exec
Q = require 'q'

dotenv.load()

PhotoFileUtils = require("./lib/photo_file_utils")
StubCameraControl = require("./lib/stub_camera_control")
PiCameraControl = require("./lib/pi_camera_control")
Template = require("./lib/template")

ImageCompositor = require("./lib/image_compositor")
DoubleImageCompositor = require("./lib/double_image_compositor")
Landscape3x8Compositor = require("./lib/landscape_3x8_compositor")

exp = express()
web = http.createServer(exp)
#template = new Template({overlayImage: "/images/landscape3x8.png", photoView: 'LandscapeOneByThree', compositor: new Landscape3x8Compositor(), printerEnabled: true, printer: 'abc'})
template = new Template({overlayImage: "/images/img_photobooth.png", photoView: 'PortraitOneByFour', compositor: new DoubleImageCompositor(), printerEnabled:true, printer: '-d dye -o fit-to-page -o PageSize=w288h432-div2 -o StpLaminate=Glossy'})
# template = new Template({overlayImage: "/images/overlay.png", photoView: 'LandscapeTwoByTwo', compositor: new ImageCompositor()})
console.log("printer is: #{template.printerEnabled}")

exp.configure ->
  exp.set "views", __dirname + "/views"
  exp.set "view engine", "jade"
  exp.use express.json()
  exp.use express.methodOverride()
  exp.use exp.router
  exp.use express.static(__dirname + "/public")

exp.get "/", (req, res) ->
  res.render "index",
    title: "shmile"
    extra_css: []

exp.get "/gallery", (req, res) ->
  res.render "gallery",
    title: "gallery!"
    extra_css: [ "photoswipe/photoswipe" ]
    image_paths: PhotoFileUtils.composited_images(true)

ccKlass = if process.env['STUB_CAMERA'] is "true" then StubCameraControl else PiCameraControl
camera = new ccKlass().init()

camera.on "photo_saved", (filename, path, web_url) ->
  template.compositor.push path

io = require("socket.io").listen(web)
web.listen 3000
io.sockets.on "connection", (websocket) ->
  console.log "Web browser connected"

  compositor = template.compositor.init();

  websocket.emit "template", template

  camera.on "camera_begin_snap", ->
    websocket.emit "camera_begin_snap"

  camera.on "camera_snapped", ->
    websocket.emit "camera_snapped"

  camera.on "photo_saved", (filename, path, web_url) ->
    websocket.emit "photo_saved",
      filename: filename
      path: path
      web_url: web_url

  websocket.on "snap", () ->
    camera.emit "snap"

  # websocket.on "all_images", ->

  shouldPrintDefer = Q.defer();
  imageCompositedDefer = Q.defer()

  websocket.on "print", ->
    console.log 'should print'
    shouldPrintDefer.resolve true
    # shouldPrint = true

  websocket.on "do_not_print", ->
    console.log 'Should NOT print'
    # shouldPrint = false
    shouldPrintDefer.reject 'not printing'

  compositor.on "composited", (output_file_path) ->
    console.log "Finished compositing image. Output image is at ", output_file_path
    template.compositor.clearImages()
    imageCompositedDefer.resolve output_file_path

    websocket.broadcast.emit "composited_image", PhotoFileUtils.photo_path_to_url(output_file_path)

  websocket.on "composite", ->
    shouldPrintDefer = Q.defer()
    imageCompositedDefer = Q.defer()

    if template.printerEnabled
      console.log "The printer is enabled, showing message"
      websocket.emit "printer_enabled"
    else
      console.log "The printer is NOT enabled, proceeding to 'review_composited'"
      websocket.emit "review_composited"

    compositor.emit "composite", template.overlayImage

    Q.all([shouldPrintDefer.promise, imageCompositedDefer.promise]).then (value) ->
      # this part will run after all promises have finished
      console.log 'yay my promises finished'
      output_file_path = value[1]
      console.log "Printing image from #{output_file_path}"
      # exec "lpr -o #{process.env.PRINTER_IMAGE_ORIENTATION} -o media=\"#{process.env.PRINTER_MEDIA}\" #{output_file_path}"
      console.log  "lp #{template.printer} #{output_file_path}"
      exec "lp #{template.printer} #{output_file_path}"

  compositor.on "generated_thumb", (thumb_path) ->
    websocket.broadcast.emit "generated_thumb", PhotoFileUtils.photo_path_to_url(thumb_path)
