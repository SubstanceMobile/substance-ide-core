decompile = require 'jdjs'
CSON = require 'season'
path = require 'path'
fs = require 'fs-plus'
module.exports = KotlinIndexer =

  ###################
  # Index Management
  ###################

  ### Example Data Structure for Reference
    timestamp: # When JAR was last modified
    packages: [
      {name: "a.b.c", id: p1}
      {name: "e.f.g", id: p2}
    ],
    functions:[
      {
        name: exec
        private: true
        class: 2
        final: true # Weather or not it can be overrided
        return: string
        arguments: [
          Array<String>,
          Array<Int>
        ]
      }
    ],
    classes:[
      {
        id: 1
        name: Bar
        super: Foo
        private: false
        final: true
        in: p1
        args: [
          "java.lang.String",
          "java.lang.Integer"
        ]
      }, {
        id: 2
        name: Bar
        super: Foo
        private: false
        final: true
        in: 1
        args: [
          "java.lang.String",
          "java.lang.Integer"
        ]
      }, {
        id: 3
        name: Baz
        super: Bar
        private: false
        final: true
        in: p2
        args: [
          "java.lang.String",
          "java.lang.Integer"
        ]
      }
    ]
    fields:[
      {
        name: Test
        type: java.lang.String
        class: 1
        mutable: false
        private: false
      }, {
        name: Bar
        type: int
        class 3
        mutable: true
        private: true
      }
    ]
  ###

  # NOTE:
    # 'indexProject' - Task to index the project
    # 'indexLibs' - Task to index the libraries
  # TODO: Find a way to find the current scope (find out which class we are in)
  # TODO: Make the whole thing async

  ProjectJar: 'project.jar'
  LibsJar: 'libs.jar'

  canIndex: () ->
    @basePath = path.join(atom.project.getDirectories().filter((d) -> d.contains(atom.workspace.getActiveTextEditor().getPath()))[0].getPath(), 'build', 'index') # Update the project location
    fs.existsSync(path.join(@basePath, '..', '..', atom.config.get 'build-fusion.advanced.buildFile'))

  index: () -> # Builds a database of all of the objects in the current project. This is used for autocomplete and other IDE features
    @stopListening() # Unsubscribe from listening to the current project

    new Promise (resolve) =>
      console.log 'Indexing Project'
      @make(@ProjectJar) if @need(@ProjectJar)
      @make(@LibsJar, true) if @need(@LibsJar)
      @startListening()
      resolve 'Index updated!'

  startListening: () ->
    listener = () =>
      @index()
      console.log 'File changed'
    try
      fs.watchFile(path.join(@basePath, @ProjectJar), listener)
    catch error
      console.log error
    try
      fs.watchFile(path.join(@basePath, @LibsJar), listener)
    catch error
      console.log error

  stopListening: () ->
    try
      fs.unwatchFile(path.join(@basePath, @ProjectJar))
    catch error#     for val in cls.fields # Feilds
        #       type = 'value'
        #       for fun in cls.methods
        #         if fun.name is "set#{val.name.charAt(0).toUpperCase() + val.name.slice(1).toLowerCase()}"
        #           type = 'variable'
        #           break
        #       create val.name, val.name, type, simplifyName val.type
    try
      fs.unwatchFile(path.join(@basePath, @LibsJar))
    catch error

  read: (source) ->
    try
      unless source is @LibsJar
        unless @sourceIndex
          @sourceIndex = CSON.parse(fs.readFileSync(path.join(@basePath, '..', '..', '.ide', 'code_index.cson')).toString())
        return @sourceIndex
      else
        unless @libsIndex
          @libsIndex = CSON.parse(fs.readFileSync(path.join(@basePath, '..', '..', '.ide', 'libraries_index.cson')).toString())
        return @libsIndex
    catch error
      return {timestamp:0,classes:[],fields:[],functions:[]}

  write: (input, source) -> # Save output to
    unless source is @LibsJar
      @sourceIndex = input
    else
      @libsIndex = input
    fs.writeFile path.join(@basePath, '..', '..', '.ide', unless source is @LibsJar then 'code_index.cson' else 'libraries_index.cson'), CSON.stringify(input), (error) =>
      if error then throw console.error error else console.log 'Saved!'

  need: (source) -> # Check if it is necessary to rebuild the index from the source JAR provided
    val = @read(source).timestamp < Date.parse(fs.statSyncNoException(path.join(@basePath, source)).mtime)
    console.log "#{source} needs to be indexed: #{val}"
    return val

  invalidateCaches: () -> # Force the index to rebuild
    try # Remove the index for code
      fs.remove(path.join(@basePath, '..', '..', '.ide', 'code_index.cson'))
      fs.remove(path.join(@basePath, @ProjectJar))
    catch error
    try # Remove the index for libraries
      fs.remove(path.join(@basePath, '..', '..', '.ide', 'libraries_index.cson'))
      fs.remove(path.join(@basePath, @LibsJar))
    catch error

  make: (source, ignorePrivate = false) -> # Read from the source and index the code
    console.log "Indexing #{source}"
    jar = path.join(@basePath, source)
    decompile(jar).then (obj) =>
      out = {} # Create the object
      out.timestamp = Date.parse(fs.statSyncNoException(jar).mtime)

      # Create the necessary arrays
      out.classes = []
      out.fields = []
      out.functions = []
      out.packages = []

      for klass in obj # For all of the classes in the source
        randID = @uuid().generate() # Generate a random identifier for this class, which will be used to look up things later

        for field in klass.fields # All of the fields in each class
          gen = {}
          gen.class = randID
          gen.name = field.name
          gen.type = field.type
          gen.mutable = not field.modifiers.includes('final')
          gen.private = field.modifiers.includes('private')
          out.fields.push gen unless ignorePrivate and gen.private

        constructor = []

        for fun in klass.methods # All of the functions in each class
          gen = {}
          gen.class = randID
          gen.name = fun.name
          gen.return = fun.signature.returnValue
          gen.private = fun.modifiers.includes('private')
          gen.final = fun.modifiers.includes('final')
          gen.arguments = fun.signature.arguments
          out.functions.push gen unless gen.name.startsWith('set') or gen.name.startsWith('get') or (gen.name is "<init>") or (ignorePrivate and gen.private)
          if gen.name is "<init>"
            constructor = gen.arguments

        thisPackage = {name: require('../../misc/importer').package(klass.name), id: @uuid().generate()} # Packages
        out.packages.push(thisPackage) if (out.packages.filter (pkg) -> return pkg.name is thisPackage.name).length is 0

        gen = {} # Create the object for the whole class
        gen.id = randID
        gen.name = if klass.name.endsWith("Kt") then thisPackage.name + ".PACKAGE" else klass.name
        gen.super = klass.super
        gen.modifiers = klass.modifiers
        gen.args = constructor
        gen.in = if gen.name.includes("$") then require("../model").lookup(gen.name.split("$").slice(0, -1).join("$"))[0]?.id else thisPackage.id
        out.classes.push gen unless ignorePrivate and klass.modifiers.includes('private')

      console.log "Project Indexer for #{source}: Success. Raw Index: ", obj, "Final index: ", out, " Timestamp: ", out.timestamp
      @write out, source # Output the index to the file

  ###################
  # Search the index
  ###################

  get: () ->
    [{
      classes: [].concat @sourceIndex.classes, @libsIndex.classes
      fields: [].concat @sourceIndex.fields, @libsIndex.fields
      functions: [].concat @sourceIndex.functions, @libsIndex.functions
      packages: [].concat @sourceIndex.packages, @libsIndex.packages
    }]

  ##########
  # Utility
  ##########

  ###
  # Fast UUID generator, RFC4122 version 4 compliant.
  # @author Jeff Ward (jcward.com).
  # @license MIT license
  # @link http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript/21963136#21963136
  #
  ###
  uuid: () ->
    self = {}
    lut = []
    i = 0
    while i < 256
      lut[i] = (if i < 16 then '0' else '') + i.toString(16)
      i++

    self.generate = ->
      d0 = Math.random() * 0xffffffff | 0
      d1 = Math.random() * 0xffffffff | 0
      d2 = Math.random() * 0xffffffff | 0
      d3 = Math.random() * 0xffffffff | 0
      lut[d0 & 0xff] + lut[d0 >> 8 & 0xff] + lut[d0 >> 16 & 0xff] + lut[d0 >> 24 & 0xff] + '-' + lut[d1 & 0xff] + lut[d1 >> 8 & 0xff] + '-' + lut[d1 >> 16 & 0x0f | 0x40] + lut[d1 >> 24 & 0xff] + '-' + lut[d2 & 0x3f | 0x80] + lut[d2 >> 8 & 0xff] + '-' + lut[d2 >> 16 & 0xff] + lut[d2 >> 24 & 0xff] + lut[d3 & 0xff] + lut[d3 >> 8 & 0xff] + lut[d3 >> 16 & 0xff] + lut[d3 >> 24 & 0xff]

    return self
