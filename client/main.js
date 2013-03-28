/*!
 *
 *  Copyright (c) David Bushell | http://dbushell.com/
 *
 */
(function(window, document, undefined)
{
    // normalize vendor prefixes
    var doc = document.documentElement;

    var transform_prop = window.Modernizr.prefixed('transform'),
        transition_prop = window.Modernizr.prefixed('transition'),
        transition_end = (function() {
            var props = {
                'WebkitTransition' : 'webkitTransitionEnd',
                'MozTransition'    : 'transitionend',
                'OTransition'      : 'oTransitionEnd otransitionend',
                'msTransition'     : 'MSTransitionEnd',
                'transition'       : 'transitionend'
            };
            return props.hasOwnProperty(transition_prop) ? props[transition_prop] : false;
        })();

    window.App = (function()
    {

        var _init = false, app = { },

            nav_open = false,

            nav_class = 'nav-open';


        app.init = function()
        {
            if (_init) {
                return;
            }
            _init = true;

            var closeNavEnd = function(e)
            {
                if (e && e.target === document.getElementsByClassName('nInnerWrap')[0]) {
                    document.removeEventListener(transition_end, closeNavEnd, false);
                }
                nav_open = false;
            };

            app.closeNav = function()
            {
                if (nav_open) {
                    // close navigation after transition or immediately
                    var inner = document.getElementsByClassName('nInnerWrap')[0];
                    var duration = (transition_end && transition_prop) ?
                        parseFloat(
                          window.getComputedStyle(inner, '')[transition_prop + 'Duration'])
                        : 0;
                    if (duration > 0) {
                        document.addEventListener(transition_end, closeNavEnd, false);
                    } else {
                        closeNavEnd(null);
                    }
                }
                $(doc).removeClass(nav_class);
            };

            app.openNav = function()
            {
                if (nav_open) {
                    return;
                }
                $(doc).addClass(nav_class);
                nav_open = true;
            };

            app.toggleNav = function(e)
            {
                if (nav_open && $(doc).hasClass(nav_class)) {
                    app.closeNav();
                } else {
                    app.openNav();
                }
                if (e) {
                    e.preventDefault();
                }
            };

            // open nav with main "nav" button
            $(".nMenuToggleButton").on("click", app.toggleNav);

            // close nav by touching the partial off-screen content
            document.addEventListener('click', function(e)
            {
                if (nav_open && !$(e.target).parents().add(e.target).hasClass('nNavigation')) {
                    e.preventDefault();
                    app.closeNav();
                }
            },
            true);

        };

        return app;

    })();

    if (window.addEventListener) {
        window.addEventListener('DOMContentLoaded', window.App.init, false);
    }

})(window, window.document);
