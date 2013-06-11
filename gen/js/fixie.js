(function() {
  var Editor, Fixie, Preview, enqueue_children, handlebars_render, render, verbose, _ref, _ref1,
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

  enqueue_children = function(el, queue) {
    var _i, _len, _ref;
    if (el.children) {
      _ref = el.children;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        el = _ref[_i];
        queue.push(el);
      }
    }
  };

  Editor = (function(_super) {
    __extends(Editor, _super);

    function Editor() {
      this.initialize = __bind(this.initialize, this);
      this.events = __bind(this.events, this);
      this.exec_cmd = __bind(this.exec_cmd, this);
      this.render = __bind(this.render, this);
      this.on_edit = __bind(this.on_edit, this);
      this.save = __bind(this.save, this);
      this._on_edit_core = __bind(this._on_edit_core, this);
      this.clean_editor_content = __bind(this.clean_editor_content, this);
      this._clean_node_core = __bind(this._clean_node_core, this);
      this.cmd = __bind(this.cmd, this);
      _ref = Editor.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Editor.prototype.template = 'fixie-editor';

    Editor.prototype.cmd = function(cmd_name) {
      return console.log("Fixie.Editor : info : running command '" + cmd_name + "'");
    };

    Editor.prototype.scrub_link = function(link) {
      var bad_predicate, good_predicate, invalid_link_predicates, valid_link_predicates, _i, _j, _len, _len1;
      invalid_link_predicates = [/javascript/];
      valid_link_predicates = [/^https:\/\//, /^http:\/\//, /^\//];
      for (_i = 0, _len = invalid_link_predicates.length; _i < _len; _i++) {
        bad_predicate = invalid_link_predicates[_i];
        if (bad_predicate.test(link)) {
          console.log("scrub_link : warning : link " + link + " was scrubbed as invalid");
          return null;
        }
      }
      for (_j = 0, _len1 = valid_link_predicates.length; _j < _len1; _j++) {
        good_predicate = valid_link_predicates[_j];
        if (good_predicate.test(link)) {
          return link;
        }
      }
    };

    Editor.prototype.bare_scrubber = function(el, queue) {
      var i;
      enqueue_children(el, queue);
      i = el.attributes.length - 1;
      while (i >= 0) {
        el.removeAttributeNode(el.attributes.item(i));
        i = i - 1;
      }
    };

    Editor.prototype.keep_children_scrubber = function(el, queue) {
      var childNodes, i;
      enqueue_children(el, queue);
      childNodes = el.childNodes;
      if (childNodes) {
        i = childNodes.length - 1;
        while (i >= 0) {
          el.parentNode.insertBefore(childNodes[i], el);
          i = i - 1;
        }
      }
      el.parentNode.removeChild(el);
    };

    Editor.prototype.link_scrubber = function(attribute, scrub_link) {
      return function(el, queue) {
        var scrubbed_attr;
        enqueue_children(el, queue);
        scrubbed_attr = null;
        if (el.hasAttribute(attribute)) {
          scrubbed_attr = scrub_link(el.getAttribute(attribute));
        }
        Editor.prototype.bare_scrubber(el, queue);
        if (scrubbed_attr) {
          el.setAttribute(attribute, scrubbed_attr);
        }
      };
    };

    Editor.prototype.tag_filter_rules = {
      'a': Editor.prototype.link_scrubber('href', Editor.prototype.scrub_link),
      'img': Editor.prototype.link_scrubber('src', Editor.prototype.scrub_link),
      'b': Editor.prototype.bare_scrubber,
      'i': Editor.prototype.bare_scrubber,
      'br': Editor.prototype.bare_scrubber,
      'p': Editor.prototype.bare_scrubber,
      'strong': Editor.prototype.bare_scrubber,
      'em': Editor.prototype.bare_scrubber,
      'ul': Editor.prototype.bare_scrubber,
      'ol': Editor.prototype.bare_scrubber,
      'li': Editor.prototype.bare_scrubber,
      'div': Editor.prototype.bare_scrubber
    };

    Editor.prototype._clean_node_core = function(node) {
      var el, queue, tagName, tag_filter;
      if (!node) {
        return;
      }
      queue = [];
      enqueue_children(node, queue);
      while (queue.length > 0) {
        el = queue.pop();
        tagName = el.tagName.toLowerCase();
        if (!(tagName in this.tag_filter_rules)) {
          this.keep_children_scrubber(el, queue);
        } else {
          tag_filter = this.tag_filter_rules[tagName];
          if (typeof tag_filter !== 'function') {
            throw new Error('Fixie : error : found a tag_filter that wasn\'t a function');
          }
          tag_filter(el, queue);
        }
      }
    };

    Editor.prototype.clean_editor_content = function() {
      var content, error;
      content = this.$('div.fixie-editor-content')[0];
      try {
        this._clean_node_core(content);
      } catch (_error) {
        error = _error;
        console.log('Fixie : error : clean_editor_content');
        return '';
      }
      return content.innerHTML;
    };

    Editor.prototype._on_edit_core = function() {
      var prop_set;
      console.log("Fixie.Editor : info : " + this.options.property + " was edited");
      prop_set = {};
      prop_set[this.options.property] = this.clean_editor_content();
      this.model.set(prop_set);
      if (this.save_timer) {
        window.clearTimeout(this.save_timer);
      }
      return this.save_timer = window.setTimeout(this.save, this.options.save_timeout || 2000);
    };

    Editor.prototype.save = function() {
      console.log("Fixie.Editor : info : saving model for property " + this.options.property);
      return this.model.save();
    };

    Editor.prototype.on_edit = function() {
      if (this.edit_timer) {
        window.clearTimeout(this.edit_timer);
      }
      return this.edit_timer = window.setTimeout(this._on_edit_core, 250);
    };

    Editor.prototype.render = function() {
      var context, template, template_result, toolbar_item, _i, _len, _ref1;
      template = this.options.template || this.template;
      context = {
        content: this.model.get(this.options.property)
      };
      template_result = render(template, context);
      this.$el.html(template_result);
      _ref1 = this.$('.fixie-toolbar-item');
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        toolbar_item = _ref1[_i];
        toolbar_item.onmousedown = function() {
          return event.preventDefault();
        };
      }
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
      return this.listenToOnce(this.model, "change:" + this.options.property, this.render);
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