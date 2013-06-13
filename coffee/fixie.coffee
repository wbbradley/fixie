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
    Editor::bare_scrubber el, queue
    if scrubbed_attr
      el.setAttribute attribute, scrubbed_attr
    return

class Editor extends Backbone.View
  cmd: (cmd_name) =>
    console.log "Fixie.Editor : info : running command '#{cmd_name}'"

  _clean_node_core: (node, rules) =>
    if not node
      return

    queue = []
    
    enqueue_children node, queue

    while queue.length > 0
      el = queue.pop()
      tagName = el.tagName.toLowerCase()
      if tagName not of rules
        keep_children_scrubber el, queue
      else
        tag_filter = @tag_filter_rules[tagName]
        if typeof tag_filter isnt 'function'
          throw new Error 'Fixie : error : found a tag_filter that wasn\'t a function'
        tag_filter el, queue
    return

  clean_editor_content: =>
    content = @$('div.fixie-editor-content')[0]

    try
      @_clean_node_core content, _.result(@, 'rules')
    catch error
      console.log 'Fixie : error : clean_editor_content'
      return ''
    return content.innerHTML

  _on_edit_core: =>
    console.log "Fixie.Editor : info : #{@options.text} was edited"
    prop_set = {}
    prop_set[@options.text] = @clean_editor_content()
    @model.set prop_set

    if @save_timer
      window.clearTimeout(@save_timer)
    @save_timer = window.setTimeout @save, @options.save_timeout or 2000

  save: =>
    console.log "Fixie.Editor : info : saving model for property #{@options.text}"
    @model.save()

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
    @listenTo @model, 'change', @render
    @render()

class URLEditor extends Editor
  template: 'fixie-url-editor'
  rules: {}
  events: =>
    'blur div.fixie-editor-content': @on_edit
    'keyup div.fixie-editor-content': @on_edit
    'paste div.fixie-editor-content': @on_edit
    'click input.fixie-url-link-edit': @on_link_edit
 
  on_link_edit: =>
    link = window.prompt 'Please enter a URL:', @model.get(@options.link_url)
    prop_set = {}
    prop_set[@options.link_url] = link
    @model.save prop_set
    @render()

  render: =>
    template = (_.result @options, 'template') or (_.result @, 'template')
    context =
      link_url: @model.get(@options.link_url)
      text: @model.get(@options.text)
    template_result = render template, context
    @$el.html(template_result)
    if not @model.has(@options.text) or not @model.has(@options.link_url)
      @listenToOnce @model, "change", @render
    @

  initialize: =>
    # TODO consider pre-scrubbing the HTML prior to rendering
    do @render

class PlainTextEditor extends Editor
  template: 'fixie-plain-editor'
  rules: {}
  events: =>
    'blur div.fixie-editor-content': @on_edit
    'keyup div.fixie-editor-content': @on_edit
    'paste div.fixie-editor-content': @on_edit
  
  render: =>
    template = (_.result @options, 'template') or (_.result @, 'template')
    context =
      text: @model.get(@options.text)
    template_result = render template, context
    @$el.html(template_result)
    if not @model.has(@options.text)
      @listenToOnce @model, "change:#{@options.text}", @render
    @

  initialize: =>
    # TODO consider pre-scrubbing the HTML prior to rendering
    do @render


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
  exec_cmd: =>
    $node = $(event.target)
    if document.execCommand
      command = $node.data('fixie-cmd')
      console.log "Fixie.Editor : info : running command '#{command}'"
      document.execCommand command
      @on_edit()
      return
    else
      throw new Error 'Fixie.Editor : error : document.execCommand not supported'
  events: =>
    'click div.fixie-toolbar-item': @exec_cmd
    'blur div.fixie-editor-content': @on_edit
    'keyup div.fixie-editor-content': @on_edit
    'paste div.fixie-editor-content': @on_edit

  render: =>
    template = (_.result @options, 'template') or (_.result @, 'template')
    context =
      text: @model.get(@options.text)
    template_result = render template, context
    @$el.html(template_result)

    for toolbar_item in @$('.fixie-toolbar-item')
      toolbar_item.onmousedown = -> event.preventDefault()

    if not @model.has(@options.text)
      @listenToOnce @model, "change:#{@options.text}", @render

    @

  initialize: =>
    # TODO consider pre-scrubbing the HTML prior to rendering
    do @render



class Fixie
  @PlainTextEditor = PlainTextEditor
  @RichTextEditor = RichTextEditor
  @URLEditor = URLEditor
  @Preview = Preview

@Fixie = Fixie
