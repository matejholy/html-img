{ EventEmitter } = require 'events'
{ $, Point, Range } = require 'atom'
Languages = require './Languages'
Size = require './languages/helper/Size'

{ inspect } = require 'util'


module.exports =
class Watcher extends EventEmitter

  # Life-cycle

  constructor: (@editorView, @languages) ->
    super()
    @languages = Languages.getInstance()
    @isActive = false
    @editor = @editorView.editor
    @editor.on 'grammar-changed', @checkGrammar
    @editor.on 'destroyed', @onDestroyed
    @checkGrammar()

  destruct: =>
    @removeAllListeners()
    @deactivate()
    @editor.off 'grammar-changed', @checkGrammar
    @editor.off 'destroyed', @onDestroyed

    delete @editorView
    delete @editor
    delete @languages

  onDestroyed: =>
    @emit 'destroyed', @


  # Enabled-disabled-cycle

  checkGrammar: =>
    @deactivate()
    language = @editor.getGrammar().name.toLowerCase()
    return unless (@language = @languages.getDefinition language)?
    @activate()

  activate: ->
    return if @isActive

    # Start listening
    @editorView.on 'html-img:fill', @onFillTriggered
    @editorView.on 'html-img:fill-width', @onFillTriggered
    @editorView.on 'html-img:fill-height', @onFillTriggered

  deactivate: ->
    return unless @isActive

    # Stop listening
    @editorView.off 'html-img:fill', @onFillTriggered
    @editorView.off 'html-img:fill-width', @onFillTriggered
    @editorView.off 'html-img:fill-height', @onFillTriggered

    # Remove references
    delete @language

  onFillTriggered: (e) =>
    textBuffer = @editor.buffer
    base = @editor.getUri()
    for cursor in @editor.cursors
      node = @language.find cursor, textBuffer
      if node?
        do (node) =>
          path = node.getPath base
          # console.log path
          $img = $ '<img>'
          .one 'load', =>
            # console.log inspect [path, $img.width(), $img.height()]
            text = @language.replace node, new Size $img.width(), $img.height()
            if text?
              textBuffer.setTextInRange node.range, text
            $img.remove()
          .attr 'src', path
          .hide()
          .appendTo @editorView.overlayer
    e.abortKeyBinding()
