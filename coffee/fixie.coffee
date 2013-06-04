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


class Editor extends Backbone.View
  template: 'fixie-editor'

  cmd: (cmd_name) =>
    console.log "Fixie.Editor : info : running command '#{cmd_name}'"

  clean_editor_content: =>
    content = @$('div.fixie-editor-content').html()
    return content

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
