this["RDTemplates"] = this["RDTemplates"] || {};

this["RDTemplates"]["template/account.html"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  


  return "<h3>Your RealDart Account</h3>\n\n<a href = \"auth/facebook\"> facebook connect </a>\n<br>\n\n<a href = \"auth/linkedin\"> linkedin connect </a>";
  });

this["RDTemplates"]["template/home.html"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  


  return "<h3>Welcome to RealDart</h3>\n\n<a href='#login'>login</a>\n\n<a href='#register'>register</a>";
  });

this["RDTemplates"]["template/login.html"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  


  return "<h3>Login</h3>\n\n<form action=\"/login\" method=\"post\">\n  <div>\n    <label>Username:</label>\n    <input type=\"text\" name=\"username\"/>\n  </div>\n  <div>\n    <label>Password:</label>\n    <input type=\"password\" name=\"password\"/>\n  </div>\n  <div>\n    <input type=\"submit\" value=\"Log In\"/>\n  </div>\n</form>\n\n<a href='#register'>register</a>";
  });

this["RDTemplates"]["template/mainLayout.html"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  


  return "<div id='rdHeader'></div>\n<div id='rdContent' class='container'></div>\n<div id='rdFooter'></div>";
  });

this["RDTemplates"]["template/mainLayout/footer.html"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  


  return "<div class='container'>\n  <p>Sidekick Labs.</p>\n</div>";
  });

this["RDTemplates"]["template/mainLayout/header.html"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  


  return "<!-- Fixed navbar -->\n<div class=\"navbar navbar-default navbar-fixed-top\" role=\"navigation\">\n  <div class=\"container\">\n    <div class=\"navbar-header\">\n      <button type=\"button\" class=\"navbar-toggle\" data-toggle=\"collapse\" data-target=\".navbar-collapse\">\n        <span class=\"sr-only\">Toggle navigation</span>\n        <span class=\"icon-bar\"></span>\n        <span class=\"icon-bar\"></span>\n        <span class=\"icon-bar\"></span>\n      </button>\n      <a class=\"navbar-brand\" href=\"#\">RealDart</a>\n    </div>\n    <div class=\"navbar-collapse collapse\">\n      <ul class=\"nav navbar-nav\">\n        <li class=\"active\"><a href=\"#\">Home</a></li>\n      </ul>\n      <ul class=\"nav navbar-nav navbar-right\">\n        <li><a href=\"#home\">About</a></li>\n      </ul>\n    </div><!--/.nav-collapse -->\n  </div>\n</div>";
  });

this["RDTemplates"]["template/register.html"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  


  return "<h3>Register</h3>\n\n<span class='error' id='registerError' style='display:none;'></span>\n\n<form id='registerForm'>\n\n  <div>\n    <label for='firstName'>First name:</label>\n    <input type='text' id='firstName' name='firstName'/>\n  </div>\n  <div>\n    <label for='lastName'>Last name:</label>\n    <input type='text' id='lastName' name='lastName'/>\n  </div>\n  <div>\n    <label for='email'>Email:</label>\n    <input type='email' id='email' name='email'/>\n  </div>\n  <div>\n    <label for='password'>Password:</label>\n    <input type='password' id='password' name='password'/>\n  </div>\n  <div>\n    <label for='password2'>Confirm password:</label>\n    <input type='password' id='password2' name='password2'/>\n  </div>\n  <div>\n    <input type='submit' value='Register' name='register'/>\n  </div>\n\n</form>\n\n<a href='#login'>login</a>";
  });