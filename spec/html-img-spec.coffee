{ join, resolve, extname } = require 'path'
{ readdirSync } = require 'fs'
{ inspect } = require 'util'
{ WorkspaceView } = require 'atom'


openFile = (filename) ->
  atom.workspaceView = new WorkspaceView
  atom.project.setPath join __dirname, 'fixtures'
  atom.workspaceView.openSync filename
  atom.workspaceView.attachToDom()
  editorView = atom.workspaceView.getActiveView()
  editor = editorView.getEditor()
  { editorView, editor }

loadGrammar = (grammar) ->
  languagePath = atom.packages.resolvePackagePath "language-#{grammar}"
  grammarsPath = resolve languagePath, 'grammars'
  for filename in readdirSync grammarsPath
    atom.syntax.loadGrammarSync resolve grammarsPath, filename

activatePackage = (name, callback) ->
  activationPromise = atom.packages.activatePackage name
  .then ({ mainModule }) ->
    callback? mainModule.watchers[0]

assert = (file, command, expected) ->
  [ workspace ] = []
  { editorView, editor } = openFile file
  loadGrammar extname(file).replace(/^\./, '')
  waitsForPromise -> activatePackage 'html-img'
  runs ->
    editor.setCursorBufferPosition [0, 1]
    editorView.trigger command
  waits 100
  runs ->
    expect(editor.getText()).toBe("#{expected}\n")



describe "html-img", ->

  describe "supports variable types of path", ->

    describe "supports url with protocol path", ->

      it "should support url", ->
        assert 'htdocs/path-url-with-protocol.html', 'html-img:fill', '<img src="https://atom.io/assets/monitor-b3b60637a9422ab1e893c9c0820a53c2.png" width="410" height="342">'

    describe "supports url without protocol path", ->

      it "should support url", ->
        assert 'htdocs/path-url-without-protocol.html', 'html-img:fill', '<img src="//atom.io/assets/monitor-b3b60637a9422ab1e893c9c0820a53c2.png" width="410" height="342">'

    describe "supports absolute path", ->

      it "should support url", ->
        assert 'htdocs/path-absolute.html', 'html-img:fill', '<img src="/images/example.png" width="800" height="500">'

    describe "supports relative path", ->

      it "should support url", ->
        assert 'htdocs/path-relative.html', 'html-img:fill', '<img src="images/example.png" width="800" height="500">'

  describe "supports Jade", ->

    it "should support url", ->
      assert 'htdocs/jade/grammar-jade-1.jade', 'html-img:fill', 'img(src="/images/example.png", width="800", height="500")'
