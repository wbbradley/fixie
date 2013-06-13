this["App"] = this["App"] || {};
this["App"]["Handlebars"] = this["App"]["Handlebars"] || {};

this["App"]["Handlebars"]["fixie-plain-editor"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  var buffer = "", stack1, functionType="function";


  buffer += "<div class=\"fixie-editor-content\" contenteditable>";
  if (stack1 = helpers.text) { stack1 = stack1.call(depth0, {hash:{},data:data}); }
  else { stack1 = depth0.text; stack1 = typeof stack1 === functionType ? stack1.apply(depth0) : stack1; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</div>\n\n";
  return buffer;
  });

this["App"]["Handlebars"]["fixie-rich-editor"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  var buffer = "", stack1, functionType="function";


  buffer += "<div>\n	<div class=\"fixie-editor-toolbar\">\n		<div class=\"btn fixie-toolbar-item\" data-fixie-cmd=\"bold\">Bold</div>\n		<div class=\"btn fixie-toolbar-item\" data-fixie-cmd=\"italic\">Italic</div>\n		<div class=\"btn fixie-toolbar-item\" data-fixie-cmd=\"insertOrderedList\">Ordered List</div>\n		<div class=\"btn fixie-toolbar-item\" data-fixie-cmd=\"insertUnorderedList\">Bulleted List</div>\n	</div>\n	<div class=\"fixie-editor-content\" contenteditable>";
  if (stack1 = helpers.text) { stack1 = stack1.call(depth0, {hash:{},data:data}); }
  else { stack1 = depth0.text; stack1 = typeof stack1 === functionType ? stack1.apply(depth0) : stack1; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "</div>\n</div>\n\n";
  return buffer;
  });

this["App"]["Handlebars"]["fixie-url-editor"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  var buffer = "", stack1, functionType="function", escapeExpression=this.escapeExpression;


  buffer += "<a class=\"fixie-url-editor\" href=\"";
  if (stack1 = helpers.link_url) { stack1 = stack1.call(depth0, {hash:{},data:data}); }
  else { stack1 = depth0.link_url; stack1 = typeof stack1 === functionType ? stack1.apply(depth0) : stack1; }
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\" contenteditable>";
  if (stack1 = helpers.text) { stack1 = stack1.call(depth0, {hash:{},data:data}); }
  else { stack1 = depth0.text; stack1 = typeof stack1 === functionType ? stack1.apply(depth0) : stack1; }
  buffer += escapeExpression(stack1)
    + "</a>\n<input type=\"button\" class=\"btn fixie-url-link-edit\" value=\"Edit Link...\"></input>\n\n";
  return buffer;
  });