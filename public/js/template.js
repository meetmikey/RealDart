this["RDTemplates"] = this["RDTemplates"] || {};

this["RDTemplates"]["template/account.html"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  var buffer = "", stack1, stack2, functionType="function", escapeExpression=this.escapeExpression, self=this, helperMissing=helpers.helperMissing;

function program1(depth0,data) {
  
  var buffer = "", stack1, stack2, options;
  buffer += "\n  <br/>\n\n  <a class='authLink' data-service='"
    + escapeExpression(((stack1 = ((stack1 = data),stack1 == null || stack1 === false ? stack1 : stack1.key)),typeof stack1 === functionType ? stack1.apply(depth0) : stack1))
    + "'>\n    <img src='img/";
  if (stack2 = helpers.imageName) { stack2 = stack2.call(depth0, {hash:{},data:data}); }
  else { stack2 = (depth0 && depth0.imageName); stack2 = typeof stack2 === functionType ? stack2.call(depth0, {hash:{},data:data}) : stack2; }
  buffer += escapeExpression(stack2)
    + ".png' />\n  </a>\n  ";
  options = {hash:{},inverse:self.noop,fn:self.program(2, program2, data),data:data};
  stack2 = ((stack1 = helpers.ifCond || (depth0 && depth0.ifCond)),stack1 ? stack1.call(depth0, (depth0 && depth0.status), "==", "success", options) : helperMissing.call(depth0, "ifCond", (depth0 && depth0.status), "==", "success", options));
  if(stack2 || stack2 === 0) { buffer += stack2; }
  buffer += "\n  ";
  options = {hash:{},inverse:self.noop,fn:self.program(4, program4, data),data:data};
  stack2 = ((stack1 = helpers.ifCond || (depth0 && depth0.ifCond)),stack1 ? stack1.call(depth0, (depth0 && depth0.status), "==", "fail", options) : helperMissing.call(depth0, "ifCond", (depth0 && depth0.status), "==", "fail", options));
  if(stack2 || stack2 === 0) { buffer += stack2; }
  buffer += "\n\n  <br/>\n";
  return buffer;
  }
function program2(depth0,data) {
  
  
  return "\n    <span class='success'>ok!</span>\n  ";
  }

function program4(depth0,data) {
  
  
  return "\n    <span class='error'>fail!</span>\n  ";
  }

  buffer += "<h2>"
    + escapeExpression(((stack1 = ((stack1 = (depth0 && depth0.user)),stack1 == null || stack1 === false ? stack1 : stack1.fullName)),typeof stack1 === functionType ? stack1.apply(depth0) : stack1))
    + "</h2>\n\n<h3>Setup your account.  3 easy steps.</h3>\n\n<p>\n  Connect your accounts so that we can remind you to keep in touch with the people you know.\n</p>\n\n<br/>\n\n";
  stack2 = helpers.each.call(depth0, (depth0 && depth0.serviceAuth), {hash:{},inverse:self.noop,fn:self.program(1, program1, data),data:data});
  if(stack2 || stack2 === 0) { buffer += stack2; }
  return buffer;
  });

this["RDTemplates"]["template/contact.html"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  var buffer = "", stack1, stack2, functionType="function", escapeExpression=this.escapeExpression, self=this;

function program1(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "\n    "
    + escapeExpression(((stack1 = ((stack1 = (depth0 && depth0.contact)),stack1 == null || stack1 === false ? stack1 : stack1.fullName)),typeof stack1 === functionType ? stack1.apply(depth0) : stack1))
    + "\n  ";
  return buffer;
  }

function program3(depth0,data) {
  
  
  return "\n    Contact not found\n  ";
  }

function program5(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "\n  <img src='"
    + escapeExpression(((stack1 = ((stack1 = (depth0 && depth0.contact)),stack1 == null || stack1 === false ? stack1 : stack1.picURL)),typeof stack1 === functionType ? stack1.apply(depth0) : stack1))
    + "' style='width:100px;height:100px;'/>\n";
  return buffer;
  }

function program7(depth0,data) {
  
  var buffer = "", stack1, stack2;
  buffer += "\n  <br/>\n  <h4><b>Emails</b></h4>\n  ";
  stack2 = helpers.each.call(depth0, ((stack1 = (depth0 && depth0.contact)),stack1 == null || stack1 === false ? stack1 : stack1.emails), {hash:{},inverse:self.noop,fn:self.program(8, program8, data),data:data});
  if(stack2 || stack2 === 0) { buffer += stack2; }
  buffer += "\n";
  return buffer;
  }
function program8(depth0,data) {
  
  var buffer = "";
  buffer += "\n    <p>"
    + escapeExpression((typeof depth0 === functionType ? depth0.apply(depth0) : depth0))
    + "</p>\n  ";
  return buffer;
  }

function program10(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "\n  <br/>\n  <h4><b>Facebook profile</b></h4>\n  <p>\n    <pre>\n      ";
  if (stack1 = helpers.fbUser) { stack1 = stack1.call(depth0, {hash:{},data:data}); }
  else { stack1 = (depth0 && depth0.fbUser); stack1 = typeof stack1 === functionType ? stack1.call(depth0, {hash:{},data:data}) : stack1; }
  buffer += escapeExpression(stack1)
    + "\n    </pre>\n  <p>\n";
  return buffer;
  }

function program12(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "\n  <br/>\n  <h4><b>LinkedIn profile</b></h4>\n  <p>\n    <pre>\n      ";
  if (stack1 = helpers.liUser) { stack1 = stack1.call(depth0, {hash:{},data:data}); }
  else { stack1 = (depth0 && depth0.liUser); stack1 = typeof stack1 === functionType ? stack1.call(depth0, {hash:{},data:data}) : stack1; }
  buffer += escapeExpression(stack1)
    + "\n    </pre>\n  </p>\n";
  return buffer;
  }

  buffer += "<a href='#contacts'>back to contacts</a>\n\n<h3>\n  ";
  stack1 = helpers['if'].call(depth0, (depth0 && depth0.contact), {hash:{},inverse:self.program(3, program3, data),fn:self.program(1, program1, data),data:data});
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n</h3>\n\n";
  stack2 = helpers['if'].call(depth0, ((stack1 = (depth0 && depth0.contact)),stack1 == null || stack1 === false ? stack1 : stack1.picURL), {hash:{},inverse:self.noop,fn:self.program(5, program5, data),data:data});
  if(stack2 || stack2 === 0) { buffer += stack2; }
  buffer += "\n\n\n";
  stack2 = helpers['if'].call(depth0, ((stack1 = (depth0 && depth0.contact)),stack1 == null || stack1 === false ? stack1 : stack1.emails), {hash:{},inverse:self.noop,fn:self.program(7, program7, data),data:data});
  if(stack2 || stack2 === 0) { buffer += stack2; }
  buffer += "\n\n\n";
  stack2 = helpers['if'].call(depth0, (depth0 && depth0.fbUser), {hash:{},inverse:self.noop,fn:self.program(10, program10, data),data:data});
  if(stack2 || stack2 === 0) { buffer += stack2; }
  buffer += "\n\n\n";
  stack2 = helpers['if'].call(depth0, (depth0 && depth0.liUser), {hash:{},inverse:self.noop,fn:self.program(12, program12, data),data:data});
  if(stack2 || stack2 === 0) { buffer += stack2; }
  return buffer;
  });

this["RDTemplates"]["template/contacts.html"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  var buffer = "", stack1, functionType="function", escapeExpression=this.escapeExpression, self=this;

function program1(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "\n  <a href='#contact/";
  if (stack1 = helpers._id) { stack1 = stack1.call(depth0, {hash:{},data:data}); }
  else { stack1 = (depth0 && depth0._id); stack1 = typeof stack1 === functionType ? stack1.call(depth0, {hash:{},data:data}) : stack1; }
  buffer += escapeExpression(stack1)
    + "'>\n    ";
  stack1 = helpers['if'].call(depth0, (depth0 && depth0.picURL), {hash:{},inverse:self.noop,fn:self.program(2, program2, data),data:data});
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n    ";
  stack1 = helpers['if'].call(depth0, (depth0 && depth0.fullName), {hash:{},inverse:self.noop,fn:self.program(4, program4, data),data:data});
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n    ";
  stack1 = helpers['if'].call(depth0, (depth0 && depth0.primaryEmail), {hash:{},inverse:self.noop,fn:self.program(6, program6, data),data:data});
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n  </a>\n  <br/>\n";
  return buffer;
  }
function program2(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "\n      <img src=\"";
  if (stack1 = helpers.picURL) { stack1 = stack1.call(depth0, {hash:{},data:data}); }
  else { stack1 = (depth0 && depth0.picURL); stack1 = typeof stack1 === functionType ? stack1.call(depth0, {hash:{},data:data}) : stack1; }
  buffer += escapeExpression(stack1)
    + "\" style='height:20px;width:20px;'/>\n    ";
  return buffer;
  }

function program4(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "\n      ";
  if (stack1 = helpers.fullName) { stack1 = stack1.call(depth0, {hash:{},data:data}); }
  else { stack1 = (depth0 && depth0.fullName); stack1 = typeof stack1 === functionType ? stack1.call(depth0, {hash:{},data:data}) : stack1; }
  buffer += escapeExpression(stack1)
    + "\n    ";
  return buffer;
  }

function program6(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "\n      ";
  stack1 = helpers['if'].call(depth0, (depth0 && depth0.fullName), {hash:{},inverse:self.noop,fn:self.program(7, program7, data),data:data});
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n      ";
  if (stack1 = helpers.primaryEmail) { stack1 = stack1.call(depth0, {hash:{},data:data}); }
  else { stack1 = (depth0 && depth0.primaryEmail); stack1 = typeof stack1 === functionType ? stack1.call(depth0, {hash:{},data:data}) : stack1; }
  buffer += escapeExpression(stack1)
    + "\n    ";
  return buffer;
  }
function program7(depth0,data) {
  
  
  return ", ";
  }

  buffer += "<h3>Contacts</h3>\n\n<p>\n  This is your contact list...\n</p>\n\n";
  stack1 = helpers.each.call(depth0, (depth0 && depth0.contacts), {hash:{},inverse:self.noop,fn:self.program(1, program1, data),data:data});
  if(stack1 || stack1 === 0) { buffer += stack1; }
  return buffer;
  });

this["RDTemplates"]["template/home.html"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  var buffer = "", stack1, self=this;

function program1(depth0,data) {
  
  
  return "\n  <a href='#login'>login</a>\n  <br/>\n\n  <a href='#register'>register</a>\n  <br/>\n";
  }

  buffer += "<h3>Welcome to RealDart</h3>\n\nRealDart is awesome.\n<br/>\n\n";
  stack1 = helpers.unless.call(depth0, (depth0 && depth0.isLoggedIn), {hash:{},inverse:self.noop,fn:self.program(1, program1, data),data:data});
  if(stack1 || stack1 === 0) { buffer += stack1; }
  return buffer;
  });

this["RDTemplates"]["template/login.html"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  


  return "<h3>Login</h3>\n\n<span class='error' id='loginError' style='display:none;'></span>\n\n<form id='loginForm'>\n\n  <div>\n    <label for='email'>Email:</label>\n    <input type='email' id='email' name='email'/>\n  </div>\n  <div>\n    <label for='password'>Password:</label>\n    <input type='password' id='password' name='password'/>\n  </div>\n  <div>\n    <input type='submit' value='Login' name='login'/>\n  </div>\n\n</form>\n\n<a href='#register'>register</a>";
  });

this["RDTemplates"]["template/mainLayout.html"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  


  return "<div id='rdHeader'></div>\n<div id='rdContent' class='container'></div>\n<div id='rdFooter'></div>";
  });

this["RDTemplates"]["template/mainLayout/footer.html"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  


  return "<div class='navbar navbar-fixed-bottom'>\n  <div class='footerWrapper'>\n    <div class='container'>\n      <div class='footerTag'>\n        Sidekick Labs\n      </div>\n    </div>\n  </div>\n</div>";
  });

this["RDTemplates"]["template/mainLayout/header.html"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  var buffer = "", stack1, functionType="function", escapeExpression=this.escapeExpression, self=this;

function program1(depth0,data) {
  
  
  return "\n        <li><a href=\"#contacts\">Contacts</a></li>\n      ";
  }

function program3(depth0,data) {
  
  var buffer = "", stack1;
  buffer += "\n        <li><a href='#account'>Welcome, "
    + escapeExpression(((stack1 = ((stack1 = (depth0 && depth0.user)),stack1 == null || stack1 === false ? stack1 : stack1.firstName)),typeof stack1 === functionType ? stack1.apply(depth0) : stack1))
    + "</a></li>\n        <li><a href='#' id='logout'>logout</a></li>\n      ";
  return buffer;
  }

function program5(depth0,data) {
  
  
  return "\n        <li><a href='#login'>login</a></li>\n      ";
  }

  buffer += "<!-- Fixed navbar -->\n<div class=\"navbar navbar-default navbar-fixed-top\" role=\"navigation\">\n  <div class=\"container\">\n    <div class=\"navbar-header\">\n      <button type=\"button\" class=\"navbar-toggle\" data-toggle=\"collapse\" data-target=\".navbar-collapse\">\n        <span class=\"sr-only\">Toggle navigation</span>\n        <span class=\"icon-bar\"></span>\n        <span class=\"icon-bar\"></span>\n        <span class=\"icon-bar\"></span>\n      </button>\n      <a class=\"navbar-brand\" href=\"#\">RealDart</a>\n      <ul class=\"nav navbar-nav navbar-left\">\n      ";
  stack1 = helpers['if'].call(depth0, (depth0 && depth0.isLoggedIn), {hash:{},inverse:self.noop,fn:self.program(1, program1, data),data:data});
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n      </ul>\n    </div>\n    <div class=\"navbar-collapse collapse\">\n      <ul class=\"nav navbar-nav\">\n      </ul>\n      <ul class=\"nav navbar-nav navbar-right\">\n      ";
  stack1 = helpers['if'].call(depth0, (depth0 && depth0.isLoggedIn), {hash:{},inverse:self.program(5, program5, data),fn:self.program(3, program3, data),data:data});
  if(stack1 || stack1 === 0) { buffer += stack1; }
  buffer += "\n       </ul>\n    </div><!--/.nav-collapse -->\n  </div>\n</div>";
  return buffer;
  });

this["RDTemplates"]["template/register.html"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  


  return "<h3>Register</h3>\n\n<span class='error' id='registerError' style='display:none;'></span>\n\n<form id='registerForm'>\n\n  <div>\n    <label for='firstName'>First name:</label>\n    <input type='text' id='firstName' name='firstName'/>\n  </div>\n  <div>\n    <label for='lastName'>Last name:</label>\n    <input type='text' id='lastName' name='lastName'/>\n  </div>\n  <div>\n    <label for='email'>Email:</label>\n    <input type='email' id='email' name='email'/>\n  </div>\n  <div>\n    <label for='password'>Password:</label>\n    <input type='password' id='password' name='password'/>\n  </div>\n  <div>\n    <label for='password2'>Confirm password:</label>\n    <input type='password' id='password2' name='password2'/>\n  </div>\n  <div>\n    <input type='submit' value='Register' name='register'/>\n  </div>\n\n</form>\n\n<a href='#login'>login</a>";
  });