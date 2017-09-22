express = require "express"
jade = require "jade"
http = require "http"
fs = require "fs"
yaml = require "yaml"
dotenv = require "dotenv"
exec = require("child_process").exec
Q = require 'q'
bodyParser = require('body-parser')
fileUpload = require('express-fileupload');

dotenv.load()

ShmileConfig = require("./lib/shmile_config")

PhotoFileUtils = require("./lib/photo_file_utils")
StubCameraControl = require("./lib/stub_camera_control")
PiCameraControl = require("./lib/pi_camera_control")

TemplateControl = require("./lib/template_control")

exp = express()
web = http.createServer(exp)
urlEncodedParser = bodyParser.urlencoded({ extended: false })

shmileConfig = new ShmileConfig()
# config = shmileConfig.config

# TODO: Global :/
templateControl = new TemplateControl(shmileConfig.get("current_template"))
# templateControl.setTemplate(shmileConfig.currentTemplate)

console.log "currente template = #{shmileConfig.get("current_template")}"

console.log("printer is #{if shmileConfig.get("printer_enabled") then 'enabled' else 'disabled'} #{if shmileConfig.get("optional_printing") then ' with optional printing'}")

io = require("socket.io").listen(web)

exp.use(fileUpload());

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

exp.post "/config", urlEncodedParser, (req, res) ->
  console.log(req.body)
  shmileConfig.config.printer_enabled = Boolean(req.body.printerEnabled)
  shmileConfig.config.optional_printing = Boolean(req.body.optionalPrinting)
  shmileConfig.config.print_finish = req.body.printFinish
  new_template = shmileConfig.setTemplate(req.body.currentTemplate)
  templateControl.setTemplate(new_template)
  io.sockets.emit "configsChanged"
  res.redirect("/")

exp.post "/fileUpload", (req, res) ->
  # if (!req.files)
  console.log(req.files)
  return res.status(400).send('No files were uploaded.') if !req.files

  # The name of the input field (i.e. "sampleFile") is used to retrieve the uploaded file
  overlay = req.files.overlay

  # // Use the mv() method to place the file somewhere on your server
  overlay.mv "public/images/overlays/#{overlay.name}", (err) ->
  #   # if (err)
    return res.status(500).send(err) if err
  #   # res.send('File uploaded!');

  res.redirect('/config');


exp.get "/config", (req, res) ->
  res.render "config",
    title: "Config"
    currentTemplate: shmileConfig.currentTemplate
    config: shmileConfig.config
    # FIXME: hardcoded - might be acceptable considering there's not many options
    finishes: ["Matte","Glossy"]
    templates: templateControl.availableTemplates

ccKlass = if process.env['STUB_CAMERA'] is "true" then StubCameraControl else PiCameraControl
camera = new ccKlass().init()

camera.on "photo_saved", (filename, path, web_url) ->
  templateControl.template.compositor.push path


web.listen 3000
io.sockets.on "connection", (websocket) ->
  console.log "Web browser connected"

  compositor = templateControl.template.compositor.init()

  websocket.emit "template", templateControl.template

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
    templateControl.template.compositor.clearImages()
    imageCompositedDefer.resolve output_file_path

    websocket.broadcast.emit "composited_image", PhotoFileUtils.photo_path_to_url(output_file_path)

  websocket.on "composite", ->
    shouldPrintDefer = Q.defer()
    imageCompositedDefer = Q.defer()

    if shmileConfig.get("printer_enabled")
      console.log "The printer is enabled, optional_printing is #{shmileConfig.get("optional_printing")}"
      websocket.emit "printer_enabled", shmileConfig.get("optional_printing")
    else
      console.log "The printer is NOT enabled, proceeding to 'review_composited'"
      websocket.emit "review_composited"

    compositor.emit "composite", templateControl.template.overlayImage

    Q.all([shouldPrintDefer.promise, imageCompositedDefer.promise]).then (value) ->
      # this part will run after all promises have finished
      console.log 'yay my promises finished'
      output_file_path = value[1]
      console.log "Printing image from #{output_file_path}"
      # exec "lpr -o #{process.env.PRINTER_IMAGE_ORIENTATION} -o media=\"#{process.env.PRINTER_MEDIA}\" #{output_file_path}"
      printCmd = "#{shmileConfig.defaults.printerCmdLine} #{shmileConfig.defaults.printFinishCmd}#{shmileConfig.get("print_finish")} #{templateControl.template.pageLayout} #{output_file_path}"
      console.log printCmd
      exec printCmd

  compositor.on "generated_thumb", (thumb_path) ->
    websocket.broadcast.emit "generated_thumb", PhotoFileUtils.photo_path_to_url(thumb_path)
