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

class Editor extends Backbone.View
  template: 'fixie-editor'

  cmd: (cmd_name) =>
    console.log "Fixie.Editor : info : running command '#{cmd_name}'"

  src_filter: (el) ->
    src = el.attributes['src']
    el.attributes = new NamedNodeMap
    el.attributes.src = 'test'

  scrub_link: (link) ->
    invalid_link_predicates = [
      /javascript/
    ]
    valid_link_predicates = [
      /^https:\/\//
      /^http:\/\//
      /^\//
      /^[a-zA-Z0-9]/
    ]

    for bad_predicate in invalid_link_predicates
      if bad_predicate.test link
        console.log "scrub_link : warning : link #{link} was scrubbed as invalid"
        return null
    for good_predicate in valid_link_predicates
      if good_predicate.test link
        return link

  bare_scrubber: (el, queue) ->
    enqueue_children el, queue
    i = el.attributes.length - 1
    while i >= 0
      el.removeAttributeNode el.attributes.item(i)
      i = i - 1
    return

  keep_children_scrubber: (el, queue) ->
    enqueue_children el, queue
    childNodes = el.childNodes
    if childNodes
      i = childNodes.length - 1
      while i >= 0
        el.parentNode.insertBefore childNodes[i], el
        i = i - 1
    el.parentNode.removeChild el
    return

  link_scrubber: (attribute, scrub_link) ->
    return (el, queue) ->
      enqueue_children el, queue
      scrubbed_attr = null
      if el.hasAttribute attribute
        scrubbed_attr = scrub_link el.getAttribute attribute
      Editor::bare_scrubber el, queue
      if scrubbed_attr
        el.setAttribute attribute, scrubbed_attr
      return

  tag_filter_rules:
    'a': @::link_scrubber 'href', @::scrub_link
    'img': @::link_scrubber 'src', @::scrub_link
    'b': @::bare_scrubber
    'i': @::bare_scrubber
    'br': @::bare_scrubber
    'p': @::bare_scrubber
    'strong': @::bare_scrubber
    'em': @::bare_scrubber
    'ul': @::bare_scrubber
    'ol': @::bare_scrubber
    'li': @::bare_scrubber

  _clean_node_core: (node) =>
    if not node
      return

    queue = []
    
    enqueue_children node, queue

    while queue.length > 0
      el = queue.pop()
      tagName = el.tagName.toLowerCase()
      if tagName not of @tag_filter_rules
        @keep_children_scrubber el, queue
      else
        tag_filter = @tag_filter_rules[tagName]
        if typeof tag_filter isnt 'function'
          throw new Error 'Fixie : error : found a tag_filter that wasn\'t a function'
        tag_filter el, queue
    return

  clean_editor_content: =>
    content = @$('div.fixie-editor-content')[0]
    try
      @_clean_node_core content
    catch error
      console.log 'Fixie : error : clean_editor_content'
      return ''
    return content.innerHTML

  _on_edit_core: =>
    console.log "Fixie.Editor : info : #{@options.property} was edited"
    prop_set = {}
    prop_set[@options.property] = @clean_editor_content()
    @model.set(prop_set)

    if @save_timer
      window.clearTimeout(@save_timer)
    @save_timer = window.setTimeout @save, @options.save_timeout or 2000

  save: =>
    console.log "Fixie.Editor : info : saving model for property #{@options.property}"
    @model.save()

  on_edit: =>
    if @edit_timer
      window.clearTimeout @edit_timer
    @edit_timer = window.setTimeout @_on_edit_core, 250

  render: =>
    template = @options.template or @template
    context =
      content: @model.get(@options.property)
    template_result = render template, context
    @$el.html(template_result)

    for toolbar_item in @$('.fixie-toolbar-item')
      toolbar_item.onmousedown = -> event.preventDefault()

    @

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

  initialize: =>
    # TODO consider pre-scrubbing the HTML prior to rendering
    do @render
    @listenToOnce @model, "change:#{@options.property}", @render

class Preview extends Backbone.View
  render: =>
    if not @options.property
      throw new Error 'Fixie.Preview : error : you must specify a "property" on Fixie.Preview instances'
    @el.innerHTML = model.get @options.property
    @

  initialize: =>
    if  not @el
        throw new Error 'Couldn\'t find el'
    @listenTo @model, 'change', @render
    @render()

class Fixie
  @Editor = Editor
  @Preview = Preview

@Fixie = Fixie
