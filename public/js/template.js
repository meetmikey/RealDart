this["RealDart"] = this["RealDart"] || {};
this["RealDart"]["Template"] = this["RealDart"]["Template"] || {};

this["RealDart"]["Template"]["template/account.html"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  


  return "Your account page.\n<br/>\n\n<a href = \"auth/facebook\"> facebook connect </a>\n<br>\n\n<a href = \"auth/linkedin\"> linkedin connect </a>";
  });

this["RealDart"]["Template"]["template/home.html"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  


  return "Welcome to RealDart\n\n<a href='#login'>login</a>\n\n<a href='#register'>register</a>";
  });

this["RealDart"]["Template"]["template/login.html"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  


  return "<form action=\"/login\" method=\"post\">\n  <div>\n    <label>Username:</label>\n    <input type=\"text\" name=\"username\"/>\n  </div>\n  <div>\n    <label>Password:</label>\n    <input type=\"password\" name=\"password\"/>\n  </div>\n  <div>\n    <input type=\"submit\" value=\"Log In\"/>\n  </div>\n</form>\n\n<a href='#register'>register</a>";
  });

this["RealDart"]["Template"]["template/mainLayout.html"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  


  return "<div id=\"rdHeader\">\n  <!-- LARGE NAV -->\n  <div class=\"top-bar hidden-xs hidden-sm\">\n    <div class=\"container\">\n      <div id=\"largeHeader\">\n\n        <a href='#home'>\n          <div class=\"logo\"></div>\n          <div class=\"realdart\">\n            RealDart\n          </div>\n        </a>\n\n      </div>\n    </div>\n  </div>\n</div>\n\n<div id=\"rdContent\"></div>\n\n<div id=\"rdFooter\"></div>";
  });

this["RealDart"]["Template"]["template/register.html"] = Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  


  return "<form action=\"/register\" method=\"post\">\n  <div>\n    <label>Username:</label>\n    <input type=\"text\" name=\"username\"/>\n  </div>\n  <div>\n    <label>Password:</label>\n    <input type=\"password\" name=\"password\"/>\n  </div>\n  <div>\n    <label>Re-type password:</label>\n    <input type=\"password\" name=\"password2\"/>\n  </div>\n  <div>\n    <input type=\"submit\" value=\"Register\"/>\n  </div>\n</form>\n\n<a href='#login'>login</a>";
  });