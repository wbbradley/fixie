(function() {
  var Editor, Fixie, Preview, handlebars_render, render, verbose, _ref, _ref1,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  verbose = false;

  handlebars_render = function(template_name, context) {
    var output, template;
    template = App.Handlebars[template_name];
    if (template) {
      if (verbose) {
        console.log("Rendering template '" + template_name + "'");
      }
      output = template(context);
      return output;
    } else {
      throw "Fixie : error : couldn't find template '" + template_name + "'";
    }
  };

  render = handlebars_render;

  Editor = (function(_super) {
    __extends(Editor, _super);

    function Editor() {
      this.initialize = __bind(this.initialize, this);
      this.events = __bind(this.events, this);
      this.exec_cmd = __bind(this.exec_cmd, this);
      this.render = __bind(this.render, this);
      this.on_model_change = __bind(this.on_model_change, this);
      this.on_edit = __bind(this.on_edit, this);
      this._on_edit_core = __bind(this._on_edit_core, this);
      this.clean_editor_content = __bind(this.clean_editor_content, this);
      this.cmd = __bind(this.cmd, this);
      _ref = Editor.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Editor.prototype.cmd = function(cmd_name) {
      return console.log("FixieEditor : info : running command '" + cmd_name + "'");
    };

    Editor.prototype.clean_editor_content = function() {
      var content;
      content = this.$('div.fixie-editor-content').html();
      return content;
    };

    Editor.prototype._on_edit_core = function() {
      var prop_set;
      console.log("FixieEditor : info : " + this.options.property + " was edited");
      prop_set = {};
      prop_set[this.options.property] = this.clean_editor_content();
      return this.model.set(prop_set);
    };

    Editor.prototype.on_edit = function() {
      if (this.edit_timer) {
        window.clearTimeout(this.edit_timer);
      }
      return this.edit_timer = window.setTimeout(this._on_edit_core, 300);
    };

    Editor.prototype.on_model_change = function() {
      return console.log("FixieEditor : info : " + this.options.property + " changed");
    };

    Editor.prototype.render = function() {
      var context, template, template_result;
      template = 'editor';
      context = {
        content: this.model.get(this.options.property)
      };
      template_result = render(template, context);
      this.$el.html(template_result);
      this.$('.fixie-toolbar-item').on('mousedown', function() {
        return event.preventDefault();
      });
      this.$('.fixie-editor-content').on('change', function() {
        return console.log('changed');
      });
      return this;
    };

    Editor.prototype.exec_cmd = function() {
      var $node, command;
      $node = $(event.target);
      if (document.execCommand) {
        command = $node.data('fixie-cmd');
        console.log("Fixie.Editor : info : running command '" + command + "'");
        document.execCommand(command);
        this.on_edit();
      } else {
        throw new Error('Fixie.Editor : error : document.execCommand not supported');
      }
    };

    Editor.prototype.events = function() {
      return {
        'click div.fixie-toolbar-item': this.exec_cmd,
        'blur div.fixie-editor-content': this.on_edit,
        'keyup div.fixie-editor-content': this.on_edit,
        'paste div.fixie-editor-content': this.on_edit
      };
    };

    Editor.prototype.initialize = function() {
      this.render();
      return this.listenTo(this.model, "change:" + this.options.property, this.on_model_change);
    };

    return Editor;

  })(Backbone.View);

  Preview = (function(_super) {
    __extends(Preview, _super);

    function Preview() {
      this.initialize = __bind(this.initialize, this);
      this.render = __bind(this.render, this);
      _ref1 = Preview.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    Preview.prototype.render = function() {
      if (!this.options.property) {
        throw new Error('Fixie.Preview : error : you must specify a "property" on Fixie.Preview instances');
      }
      this.el.innerHTML = model.get(this.options.property);
      return this;
    };

    Preview.prototype.initialize = function() {
      if (!this.el) {
        throw new Error('Couldn\'t find el');
      }
      this.listenTo(this.model, 'change', this.render);
      return this.render();
    };

    return Preview;

  })(Backbone.View);

  Fixie = (function() {
    function Fixie() {}

    Fixie.Editor = Editor;

    Fixie.Preview = Preview;

    return Fixie;

  })();

  this.Fixie = Fixie;

}).call(this);

/*
//@ sourceMappingURL=fixie.js.map
*/