/**
 * JavaScript Inheritance Helper <br>
 * Based on <a href="http://ejohn.org/">John Resig</a> Simple Inheritance<br>
 * MIT Licensed.<br>
 * Inspired by <a href="http://code.google.com/p/base2/">base2</a> and <a href="http://www.prototypejs.org/">Prototype</a><br>
 * @param {Object} object Object (or Properties) to inherit from
 * @example
 * var Person = Object.extend(
 * {
 *    init: function(isDancing)
 *    {
 *       this.dancing = isDancing;
 *    },
 *    dance: function()
 *    {
 *       return this.dancing;
 *    }
 * });
 *
 * var Ninja = Person.extend(
 * {
 *    init: function()
 *    {
 *       this.parent( false );
 *    },
 *
 *    dance: function()
 *    {
 *       // Call the inherited version of dance()
 *       return this.parent();
 *    },
 *
 *    swingSword: function()
 *    {
 *       return true;
 *    }
 * });
 *
 * var p = new Person(true);
 * p.dance(); // => true
 *
 * var n = new Ninja();
 * n.dance(); // => false
 * n.swingSword(); // => true
 *
 * // Should all be true
 * p instanceof Person && p instanceof Class &&
 * n instanceof Ninja && n instanceof Person && n instanceof Class
 */
Object.extend = function(prop) {
  // _super rename to parent to ease code reading
  var parent = this.prototype;

  // Instantiate a base class (but only create the instance,
  // don't run the init constructor)
  initializing = true;
  var proto = new this();
  initializing = false;

  // Copy the properties over onto the new prototype
  for ( var name in prop) {
    // Check if we're overwriting an existing function
    proto[name] = typeof prop[name] === "function"
        && typeof parent[name] === "function"
        && fnTest.test(prop[name]) ? (function(name, fn) {
      return function() {
        var tmp = this.parent;

        // Add a new ._super() method that is the same method
        // but on the super-class
        this.parent = parent[name];

        // The method only need to be bound temporarily, so we
        // remove it when we're done executing
        var ret = fn.apply(this, arguments);
        this.parent = tmp;

        return ret;
      };
    })(name, prop[name]) : prop[name];
  }

  // The dummy class constructor
  function Class() {
    if (!initializing && this.init) {
      this.init.apply(this, arguments);
    }
    //return this;
  }
  // Populate our constructed prototype object
  Class.prototype = proto;
  // Enforce the constructor to be what we expect
  Class.constructor = Class;
  // And make this class extendable
  Class.extend = Object.extend;//arguments.callee;

  return Class;
};

if (typeof Object.create !== 'function') {
  /**
   * Prototypal Inheritance Create Helper
   * @param {Object} Object
   * @example
   * // declare oldObject
   * oldObject = new Object();
   * // make some crazy stuff with oldObject (adding functions, etc...)
   * ...
   * ...
   *
   * // make newObject inherits from oldObject
   * newObject = Object.create(oldObject);
   */
  Object.create = function(o) {
    function _fn() {};
    _fn.prototype = o;
    return new _fn();
  };
};