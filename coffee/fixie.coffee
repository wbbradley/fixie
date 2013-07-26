#
# Fixie.js
#
# Simple View plugin for in-place editing of Rich Text via Backbone model properties.
#
# See also:
# http://tifftiff.de/contenteditable/compliance_test.html
# https://developer.mozilla.org/en-US/docs/Rich-Text_Editing_in_Mozilla#Executing_Commands
#
verbose = false

handlebars_render = (template_name, context) ->
  template = App.Handlebars[template_name]
  if template
    if verbose
      console.log "Rendering template '#{template_name}'"
    output = template context
    return output
  else
    throw "Fixie : error : couldn't find template '#{template_name}'"

render = handlebars_render

enqueue_children = (el, queue) ->
  if el.children
    for el in el.children
      queue.push el

  return

scrub_link = (link) ->
  invalid_link_predicates = [
    /javascript/  #  Danger!
  ]
  valid_link_predicates = [
    /^https:\/\// #  HTTPS
    /^http:\/\//  #  HTTP
    /^\//         #  same hostname absolute path and protocol-retaining URL (//foo.com/bar/baz)
  ]

  for bad_predicate in invalid_link_predicates
    if bad_predicate.test link
      console.log "scrub_link : warning : link #{link} was scrubbed as invalid"
      return null
  for good_predicate in valid_link_predicates
    if good_predicate.test link
      return link

bare_scrubber = (el, queue) ->
  enqueue_children el, queue
  i = el.attributes.length - 1
  while i >= 0
    el.removeAttributeNode el.attributes.item i
    i = i - 1
  return

keep_children_scrubber = (el, queue) ->
  enqueue_children el, queue
  childNodes = el.childNodes
  if childNodes
    i = childNodes.length - 1
    while i >= 0
      el.parentNode.insertBefore childNodes[i], el
      i = i - 1
  el.parentNode.removeChild el
  return

link_scrubber = (attribute, scrub_link) ->
  return (el, queue) ->
    enqueue_children el, queue
    scrubbed_attr = null
    if el.hasAttribute attribute
      scrubbed_attr = scrub_link el.getAttribute attribute
    bare_scrubber el, queue
    if scrubbed_attr
      el.setAttribute attribute, scrubbed_attr
    return

find_command = (node) ->
  while node and node.nodeType is Node.ELEMENT_NODE
    if node.hasAttribute 'data-fixie-cmd'
      return node.getAttribute 'data-fixie-cmd'
    node = node.parentNode
  return null

class Editor extends Backbone.View
  displayError: (error) =>
    @el.style.backgroundColor = '#ffbbbb'

  initialize: =>
    @listenTo @model, "synced", =>
      @el.style.backgroundColor = 'white'
    @listenTo @model, "validation-error", (error) =>
      if error.field is @options.text
        @displayError error
      console.log
    do @render
  cmd: (cmd_name) =>
    console.log "Fixie.Editor : info : running command '#{cmd_name}'"

  _clean_node_core: (node, rules) =>
    if not node
      return

    queue = []

    # HACK: remove useless BR tags at the beginning of the contenteditable
    while node.childNodes.length > 0
      firstChild = node.childNodes[0]
      if firstChild.nodeType is Node.ELEMENT_NODE and firstChild.tagName.toLowerCase() is 'br'
        node.removeChild firstChild
      else
        break
    enqueue_children node, queue

    while queue.length > 0
      el = queue.pop()
      tagName = el.tagName.toLowerCase()
      if tagName not of rules
        keep_children_scrubber el, queue
      else
        tag_filter = rules[tagName]
        if typeof tag_filter isnt 'function'
          throw new Error 'Fixie : error : found a tag_filter that wasn\'t a function'
        tag_filter el, queue
    return

  clean_editor_content: =>
    content = @$('.fixie-editor-content')[0]
    @_clean_node_core content, _.result(@, 'rules')
    return content.innerHTML

  _on_edit_core: =>
    console.log "Fixie.Editor : info : #{@options.text} was edited"
    prop_set = {}
    prop_set[@options.text] = @clean_editor_content()
    @stopListening @model, "change:#{@options.text}"
    @model.set prop_set

  on_edit: =>
    if @edit_timer
      window.clearTimeout @edit_timer
    @edit_timer = window.setTimeout @_on_edit_core, 250


class Preview extends Backbone.View
  render: =>
    if not @options.text
      throw new Error 'Fixie.Preview : error : you must specify a "text" property name on Fixie.Preview instances'
    @el.innerHTML = model.get @options.text
    @

  initialize: =>
    if not @el
        throw new Error 'Couldn\'t find el'
    @listenTo @model, "change:#{@options.text}", @render
    @render()

class URLEditor extends Editor
  template: 'fixie-url-editor'
  rules: {}
  events: =>
    'keyup .fixie-editor-content': @on_edit
    'paste .fixie-editor-content': @on_edit
    'click .fixie-url-link-edit': @on_link_edit
 
  on_link_edit: =>
    link = window.prompt 'Please enter a URL:', @model.get(@options.link_url)
    prop_set = {}
    prop_set[@options.link_url] = (scrub_link link) or ''
    @model.set prop_set
    @render()

  render: =>
    template = (_.result @options, 'template') or (_.result @, 'template')
    context =
      link_url: @model.get(@options.link_url)
      text: @model.get(@options.text)
    template_result = render template, context
    @$el.html(template_result)
    @listenToOnce @model, 'change', @render
    @

  initialize: =>
    # TODO consider pre-scrubbing the HTML prior to rendering
    do @render

class PlainTextEditor extends Editor
  template: 'fixie-plain-editor'
  rules: {}
  events: =>
    'keyup .fixie-editor-content': @on_edit
    'paste .fixie-editor-content': @on_edit

  clean_editor_content: =>
    content = @$('.fixie-editor-content')[0].innerText
    content = content.replace(/[\r\n]/g, ' ')
    while true
      len = content.length
      content = content.replace('  ', ' ')
      if len is content.length
        break
    return content

  render: =>
    template = (_.result @options, 'template') or (_.result @, 'template')
    context =
      text: @model.get(@options.text)
    template_result = render template, context
    @$el.html(template_result)
    @listenToOnce @model, "change:#{@options.text}", @render
    @

  initialize: =>
    super


class RichTextEditor extends Editor
  template: 'fixie-rich-editor'
  rules:
    'a': link_scrubber 'href', scrub_link
    'img': link_scrubber 'src', scrub_link
    'b': bare_scrubber
    'i': bare_scrubber
    'br': bare_scrubber
    'p': bare_scrubber
    'strong': bare_scrubber
    'em': bare_scrubber
    'ul': bare_scrubber
    'ol': bare_scrubber
    'li': bare_scrubber
    'div': bare_scrubber

  dispatch: (command) =>
    if document.execCommand
      if command and document.queryCommandEnabled command
        console.log "Fixie.Editor : info : running command '#{command}'"
        document.execCommand command
        @on_edit()
      else
        console.log "Fixie.Editor : info : command #{command} is currently not enabled."
    else
      throw new Error 'Fixie.Editor : error : browser support is not available for this operation'

  insertLink: =>
    if document?.queryCommandEnabled 'createlink'
      link = scrub_link window.prompt 'Please enter a URL:', @model.get(@options.link_url)
      if link
        document.execCommand 'createlink', false, link
        @on_edit()
      else
        window.alert 'Please try again. Urls must begin with /, http://, or https://'
    console.log 'Fixie.Editor : info : createlink is not enabled'

  exec_cmd: =>
    cmd_dispatch =
      bold: @dispatch
      italic: @dispatch
      insertOrderedList: @dispatch
      insertUnorderedList: @dispatch
      insertLink: @insertLink

    command = find_command(event.target)
    if command of cmd_dispatch
      dispatch = cmd_dispatch[command](command)
    else
      throw new Error 'Fixie.Editor : error : unexepected fixie-cmd'

    return false

  events: =>
    'click .fixie-toolbar-item': @exec_cmd
    'keyup .fixie-editor-content': @on_edit
    'paste .fixie-editor-content': @on_edit

  render: =>
    template = (_.result @options, 'template') or (_.result @, 'template')
    context =
      text: @model.get(@options.text)
    template_result = render template, context
    @$el.html(template_result)

    for toolbar_item in @$('.fixie-toolbar-item')
      toolbar_item.onmousedown = -> event.preventDefault()

    @listenToOnce @model, "change:#{@options.text}", @render
    @

  initialize: =>
    # TODO consider pre-scrubbing the HTML prior to rendering
    super



class Fixie
  @PlainTextEditor = PlainTextEditor
  @RichTextEditor = RichTextEditor
  @URLEditor = URLEditor
  @Preview = Preview

@Fixie = Fixie
