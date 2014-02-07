(function() {
  window.RealDart = {
    Constant: {},
    Config: {},
    Model: {},
    Collection: {},
    Decorator: {},
    Helper: {},
    View: {
      MainLayout: {}
    }
  };

}).call(this);

(function() {
  RealDart.Constant = {
    some: 'thing'
  };

}).call(this);

(function() {
  RealDart.Config = {
    enableLogging: true
  };

}).call(this);

(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  RealDart.Router = (function(_super) {
    __extends(Router, _super);

    function Router() {
      this.render = __bind(this.render, this);
      this.scrollToTop = __bind(this.scrollToTop, this);
      this.renderLayout = __bind(this.renderLayout, this);
      this.account = __bind(this.account, this);
      this.register = __bind(this.register, this);
      this.login = __bind(this.login, this);
      this.home = __bind(this.home, this);
      this.initialize = __bind(this.initialize, this);
      return Router.__super__.constructor.apply(this, arguments);
    }

    Router.prototype._layout = null;

    Router.prototype.routes = {
      '': 'home',
      'home': 'home',
      'login': 'login',
      'register': 'register',
      'account': 'account'
    };

    Router.prototype.initialize = function() {};

    Router.prototype.home = function() {
      return this.render('Home');
    };

    Router.prototype.login = function() {
      return this.render('Login');
    };

    Router.prototype.register = function() {
      return this.render('Register');
    };

    Router.prototype.account = function() {
      return this.render('Account');
    };

    Router.prototype.renderLayout = function() {
      if (!this._layout) {
        this._layout = new RealDart.View.MainLayout();
        return this._layout.render();
      }
    };

    Router.prototype.scrollToTop = function() {
      return $('html, body').animate({
        scrollTop: 0
      }, 'slow');
    };

    Router.prototype.render = function(viewClassName, data) {
      this.renderLayout();
      this._layout.teardownSubView('rdContent');
      this._layout.addAndRenderSubview('rdContent', {
        viewClassName: viewClassName,
        selector: '#rdContent'
      }, data);
      return this.scrollToTop();
    };

    return Router;

  })(Backbone.Router);

}).call(this);

(function() {
  $(document).ready(function() {
    RealDart.router = new RealDart.Router();
    return Backbone.history.start();
  });

}).call(this);

(function() {
  var RealDartHelperLogger,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  RealDartHelperLogger = (function() {
    function RealDartHelperLogger() {
      this.doLog = __bind(this.doLog, this);
      this.error = __bind(this.error, this);
      this.log = __bind(this.log, this);
    }

    RealDartHelperLogger.prototype.log = function(msg, extra) {
      return this.doLog('log', msg, extra);
    };

    RealDartHelperLogger.prototype.error = function(msg, extra) {
      return this.doLog('error', msg, extra);
    };

    RealDartHelperLogger.prototype.doLog = function(type, msg, extra) {
      if (!RealDart.Config.enableLogging) {
        return;
      }
      if (RealDart.Helper.Utils.isUndefined(extra)) {
        return console[type](msg);
      } else {
        return console[type](msg, extra);
      }
    };

    return RealDartHelperLogger;

  })();

  RealDart.Helper.Logger = new RealDartHelperLogger();

  window.rdLog = RealDart.Helper.Logger.log;

  window.rdError = RealDart.Helper.Logger.error;

}).call(this);

(function() {
  var RealDartHelperUtils,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  RealDartHelperUtils = (function() {
    function RealDartHelperUtils() {
      this.getObjectFromString = __bind(this.getObjectFromString, this);
      this.getClassFromName = __bind(this.getClassFromName, this);
    }

    RealDartHelperUtils.prototype.capitalize = function(input) {
      var capitalized;
      if (!(input && (input.length > 0))) {
        return '';
      }
      capitalized = input[0].toUpperCase() + input.slice(1);
      return capitalized;
    };

    RealDartHelperUtils.prototype.uncapitalize = function(input) {
      var capitalized;
      if (!(input && (input.length > 0))) {
        return '';
      }
      capitalized = input[0].toLowerCase() + input.slice(1);
      return capitalized;
    };

    RealDartHelperUtils.prototype.getClassFromName = function(className) {
      return this.getObjectFromString(className);
    };

    RealDartHelperUtils.prototype.getObjectFromString = function(str) {
      var obj, strArray;
      strArray = str.split('.');
      obj = window || this;
      _.each(strArray, (function(_this) {
        return function(strArrayElement) {
          return obj = obj[strArrayElement];
        };
      })(this));
      return obj;
    };

    RealDartHelperUtils.prototype.isUndefined = function(input) {
      if (typeof input === 'undefined') {
        return true;
      }
      return false;
    };

    return RealDartHelperUtils;

  })();

  RealDart.Helper.Utils = new RealDartHelperUtils();

}).call(this);

(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  RealDart.View.Base = (function(_super) {
    __extends(Base, _super);

    function Base() {
      this._getTemplateSet = __bind(this._getTemplateSet, this);
      this._getTemplatePathFromName = __bind(this._getTemplatePathFromName, this);
      this._renderTemplate = __bind(this._renderTemplate, this);
      this._assignSubviewElement = __bind(this._assignSubviewElement, this);
      this._renderSubView = __bind(this._renderSubView, this);
      this._teardown = __bind(this._teardown, this);
      this._addSubViewDefinitionAndName = __bind(this._addSubViewDefinitionAndName, this);
      this._initializeSubviews = __bind(this._initializeSubviews, this);
      this.getTemplateData = __bind(this.getTemplateData, this);
      this.getTemplateName = __bind(this.getTemplateName, this);
      this.getSubViewDefinitions = __bind(this.getSubViewDefinitions, this);
      this.teardown = __bind(this.teardown, this);
      this.postRender = __bind(this.postRender, this);
      this.preRender = __bind(this.preRender, this);
      this.postInitialize = __bind(this.postInitialize, this);
      this.preInitialize = __bind(this.preInitialize, this);
      this.bail = __bind(this.bail, this);
      this.getRenderedTemplate = __bind(this.getRenderedTemplate, this);
      this.reloadSubView = __bind(this.reloadSubView, this);
      this.reloadSubViews = __bind(this.reloadSubViews, this);
      this.teardownSubView = __bind(this.teardownSubView, this);
      this.teardownSubViews = __bind(this.teardownSubViews, this);
      this.addAndRenderSubview = __bind(this.addAndRenderSubview, this);
      this.renderSubView = __bind(this.renderSubView, this);
      this.renderSubViews = __bind(this.renderSubViews, this);
      this.addSubView = __bind(this.addSubView, this);
      this.render = __bind(this.render, this);
      this.setSelector = __bind(this.setSelector, this);
      this.getSelector = __bind(this.getSelector, this);
      this.getParentView = __bind(this.getParentView, this);
      this.getSubView = __bind(this.getSubView, this);
      this.getSubViews = __bind(this.getSubViews, this);
      this.initialize = __bind(this.initialize, this);
      return Base.__super__.constructor.apply(this, arguments);
    }

    Base.prototype.events = {};

    Base.prototype.outsideDOMScope = false;

    Base.prototype.subViewDefinitions = {};

    Base.prototype.templateName = null;

    Base.prototype.bailPath = null;

    Base.prototype.initialize = function(data) {
      data = data || {};
      _.each(data, (function(_this) {
        return function(value, key) {
          return _this[key] = value;
        };
      })(this));
      this.preInitialize();
      this._initializeSubviews();
      this.postInitialize();
      return this;
    };

    Base.prototype.getSubViews = function() {
      return this._subViews;
    };

    Base.prototype.getSubView = function(name) {
      return this._subViews[name];
    };

    Base.prototype.getParentView = function() {
      return this._parentView;
    };

    Base.prototype.getSelector = function() {
      return this._selector;
    };

    Base.prototype.setSelector = function(selector) {
      return this._selector = selector;
    };

    Base.prototype.render = function() {
      this.preRender();
      this._renderTemplate();
      this.renderSubViews();
      this.postRender();
      return this;
    };

    Base.prototype.addSubView = function(name, subViewDefinition, subViewData) {
      var fullViewClassName, subView, subViewClass;
      fullViewClassName = 'RealDart.View.' + subViewDefinition.viewClassName;
      subViewClass = RealDart.Helper.Utils.getClassFromName(fullViewClassName);
      subViewData = subViewData || {};
      subViewData._selector = subViewDefinition.selector;
      subViewData._parentView = this;
      subViewData._classNameSuffix = subViewDefinition.viewClassName;
      if (subViewDefinition.outsideDOMScope !== void 0) {
        subViewData._outsideDOMScope = subViewDefinition.outsideDOMScope;
      }
      if (subViewDefinition.shouldRender !== void 0) {
        subViewData._shouldRender = subViewDefinition.shouldRender;
      }
      subView = new subViewClass(subViewData);
      this._subViews[name] = subView;
      this._assignSubviewElement(subView);
      return subView;
    };

    Base.prototype.renderSubViews = function(forceRender) {
      return _.each(this._subViews, (function(_this) {
        return function(subView) {
          if (subView && (forceRender || subView._shouldRender)) {
            return _this._renderSubView(subView);
          }
        };
      })(this));
    };

    Base.prototype.renderSubView = function(name) {
      return this._renderSubView(this.getSubView(name));
    };

    Base.prototype.addAndRenderSubview = function(name, subViewDefinition, subViewData) {
      this.addSubView(name, subViewDefinition, subViewData);
      return this.renderSubView(name);
    };

    Base.prototype.teardownSubViews = function() {
      return _.each(this._subViews, (function(_this) {
        return function(subViewDefinition, name) {
          return _this.teardownSubView(name);
        };
      })(this));
    };

    Base.prototype.teardownSubView = function(name) {
      var subView;
      subView = this.getSubView(name);
      if (!subView) {
        return;
      }
      subView._teardown();
      return delete this._subViews[name];
    };

    Base.prototype.reloadSubViews = function() {
      this.teardownSubViews();
      return _.each(this.getSubViewDefinitions(), (function(_this) {
        return function(subViewDefinition, name) {
          return _this.addAndRenderSubview(name, subViewDefinition);
        };
      })(this));
    };

    Base.prototype.reloadSubView = function(name) {
      var definitions, subViewDefinition;
      this.teardownSubView(name);
      definitions = this.getSubViewDefinitions();
      subViewDefinition = definitions[name];
      if (!subViewDefinition) {
        return;
      }
      return this.addAndRenderSubview(name, subViewDefinition);
    };

    Base.prototype.getRenderedTemplate = function() {
      var renderedTemplate, templateData, templateName, templatePath, templateSet;
      templateName = this.getTemplateName();
      templateData = this.getTemplateData();
      templatePath = this._getTemplatePathFromName(templateName);
      templateSet = this._getTemplateSet();
      renderedTemplate = templateSet[templatePath](templateData);
      return renderedTemplate;
    };

    Base.prototype.bail = function() {
      var bailPath;
      bailPath = this.bailPath || this._defaultBailPath;
      return RealDart.router.navigate(bailPath, {
        trigger: true
      });
    };

    Base.prototype.preInitialize = function() {};

    Base.prototype.postInitialize = function() {};

    Base.prototype.preRender = function() {};

    Base.prototype.postRender = function() {};

    Base.prototype.teardown = function() {};

    Base.prototype.getSubViewDefinitions = function() {
      return this.subViewDefinitions;
    };

    Base.prototype.getTemplateName = function() {
      if (this.templateName) {
        return this.templateName;
      }
      return this._classNameSuffix;
    };

    Base.prototype.getTemplateData = function() {
      return {};
    };

    Base.prototype._selector = null;

    Base.prototype._subViews = {};

    Base.prototype._parentView = null;

    Base.prototype._classSuffix = '';

    Base.prototype._defaultBailPath = 'home';

    Base.prototype._shouldRender = true;

    Base.prototype._initializeSubviews = function() {
      this._subViews = $.extend(true, {}, this._subViews);
      return _.each(this.getSubViewDefinitions(), this._addSubViewDefinitionAndName);
    };

    Base.prototype._addSubViewDefinitionAndName = function(subViewDefinition, name) {
      if (!(subViewDefinition && name)) {
        return;
      }
      return this.addSubView(name, subViewDefinition);
    };

    Base.prototype._teardown = function() {
      this.teardownSubViews();
      this.teardown();
      this.off();
      this.undelegateEvents();
      this.stopListening();
      return this.$el.empty();
    };

    Base.prototype._renderSubView = function(subView) {
      if (!subView) {
        return;
      }
      this._assignSubviewElement(subView);
      return subView.render();
    };

    Base.prototype._assignSubviewElement = function(subView) {
      var element, selector;
      if (!subView) {
        return;
      }
      selector = subView.getSelector();
      if (subView._outsideDOMScope) {
        element = $(selector);
      } else {
        element = this.$(selector);
      }
      return subView.setElement(element);
    };

    Base.prototype._renderTemplate = function() {
      return this.$el.html(this.getRenderedTemplate());
    };

    Base.prototype._getTemplatePathFromName = function(templateName) {
      var fullName, newPieces, path, pieces;
      fullName = 'template.' + templateName;
      pieces = fullName.split('.');
      newPieces = [];
      _.each(pieces, (function(_this) {
        return function(piece) {
          return newPieces.push(RealDart.Helper.Utils.uncapitalize(piece));
        };
      })(this));
      path = newPieces.join('/');
      path += '.html';
      return path;
    };

    Base.prototype._getTemplateSet = function() {
      return window['RealDartTemplates'];
    };

    return Base;

  })(Backbone.View);

}).call(this);

(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  RealDart.View.Account = (function(_super) {
    __extends(Account, _super);

    function Account() {
      return Account.__super__.constructor.apply(this, arguments);
    }

    return Account;

  })(RealDart.View.Base);

}).call(this);

(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  RealDart.View.Home = (function(_super) {
    __extends(Home, _super);

    function Home() {
      return Home.__super__.constructor.apply(this, arguments);
    }

    return Home;

  })(RealDart.View.Base);

}).call(this);

(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  RealDart.View.Login = (function(_super) {
    __extends(Login, _super);

    function Login() {
      return Login.__super__.constructor.apply(this, arguments);
    }

    return Login;

  })(RealDart.View.Base);

}).call(this);

(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  RealDart.View.MainLayout = (function(_super) {
    __extends(MainLayout, _super);

    function MainLayout() {
      this.preInitialize = __bind(this.preInitialize, this);
      return MainLayout.__super__.constructor.apply(this, arguments);
    }

    MainLayout.prototype.templateName = 'mainLayout';

    MainLayout.prototype.preInitialize = function() {
      return this.setElement($('#rdContainer'));
    };

    return MainLayout;

  })(RealDart.View.Base);

}).call(this);

(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  RealDart.View.Register = (function(_super) {
    __extends(Register, _super);

    function Register() {
      return Register.__super__.constructor.apply(this, arguments);
    }

    return Register;

  })(RealDart.View.Base);

}).call(this);

(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  RealDart.Model.Base = (function(_super) {
    __extends(Base, _super);

    function Base() {
      this.decorate = __bind(this.decorate, this);
      return Base.__super__.constructor.apply(this, arguments);
    }

    Base.prototype.decorate = function() {
      if (this.decorator) {
        return this.decorator.decorate(this);
      }
      return {};
    };

    return Base;

  })(Backbone.Model);

}).call(this);

(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  RealDart.Collection.Base = (function(_super) {
    __extends(Base, _super);

    function Base() {
      this.comparator = __bind(this.comparator, this);
      this.sortByField = __bind(this.sortByField, this);
      this.toggleSortOrder = __bind(this.toggleSortOrder, this);
      return Base.__super__.constructor.apply(this, arguments);
    }

    Base.prototype.compareBy = {};

    Base.prototype.sortKey = '_id';

    Base.prototype.sortOrder = 'asc';

    Base.prototype.toggleSortOrder = function() {
      if (this.sortOrder === 'asc') {
        return this.sortOrder = 'desc';
      } else {
        return this.sortOrder = 'asc';
      }
    };

    Base.prototype.sortByField = function(field) {
      if (this.sortKey === field) {
        this.toggleSortOrder();
      } else {
        this.sortOrder = 'asc';
        this.sortKey = field;
      }
      return this.sort();
    };

    Base.prototype.comparator = function(model1, model2) {
      var key, value1, value2;
      key = this.sortKey;
      value1 = this.compareBy[key] != null ? this.compareBy[key](model1) : model1.get(key);
      value2 = this.compareBy[key] != null ? this.compareBy[key](model2) : model2.get(key);
      if (value1 === value2) {
        return 0;
      }
      if (this.sortOrder === 'asc') {
        if (value1 < value2) {
          return -1;
        } else {
          return 1;
        }
      } else if (this.sortOrder === 'desc') {
        if (value1 > value2) {
          return -1;
        } else {
          return 1;
        }
      } else {
        return 0;
      }
    };

    return Base;

  })(Backbone.Collection);

}).call(this);
