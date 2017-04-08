var VERSION = '2017-03-11';

// http://stackoverflow.com/a/2548133/25507
if (typeof String.prototype.endsWith !== 'function') {
    String.prototype.endsWith = function(suffix) {
        return this.indexOf(suffix, this.length - suffix.length) !== -1;
    };
}

/**Parses query string-like parameters out of the end of the hash.
 * Based on http://stackoverflow.com/a/2880929/25507
 */
function parseHashQueryString() {
    var match,
        pl     = /\+/g,  // Regex for replacing addition symbol with a space
        search = /([^&=]+)=?([^&]*)/g,
        decode = function (s) { return decodeURIComponent(s.replace(pl, " ")); },
        query  = window.location.hash.substring(1),
        url_params = {};

    if (query.indexOf('?') != -1) {
        query = query.substring(query.indexOf('?') + 1);

        while ((match = search.exec(query))) {
           url_params[decode(match[1])] = decode(match[2]);
        }
    }

    return url_params;
}

function getData()
{
    return tome[versions.current + '-' + masteries.current];
}

function escapeHtml(s)
{
    return s.replace(/&/g, '&amp;').replace(/>/g, '&gt;').replace(/</g, '&lt;').replace(/"/g, '&quot;');
}

function locationHashNoQuery()
{
    return location.hash.replace(/\?.*/, '');
}

function currentQuery()
{
    var query = versions.asQuery();
    var mquery = masteries.asQuery();
    if (query) {
        if (mquery) query += '&' + mquery;
    } else {
        query = mquery;
    }
    return query ? '?' + query : '';
}

function setActiveNav(active_nav_route)
{
    $(".nav li").removeClass("active");
    if (active_nav_route) {
        $(".nav a[data-base-href='" + active_nav_route + "']").parent().addClass("active");
    }
}

///Updates navigation after a change
function updateNav() {
    // Update nav links to use the current version query.
    $("a[data-base-href]").each(function () {
        $(this).attr('href', $(this).attr('data-base-href') + currentQuery());
    });
}


function scrollToId()
{
    var $hash = $(locationHashNoQuery().replace(/\//g, '\\/'));
    if ($hash.length) {
        $("#content-container").scrollTop($("#content-container").scrollTop() + $hash.offset().top);
    }
}

function enableExpandCollapseAll()
{
    $(".expand-all").addClass('fa fa-toggle-down')
        .attr('title', 'Expand All');
    $(".collapse-all").addClass('fa fa-toggle-up')
        .attr('title', 'Collapse All');
    $(".expand-all, .collapse-all").addClass('clickable')
        .click(function() {
            $($(this).attr('data-target')).find('.collapse').collapse($(this).hasClass('expand-all') ? 'show' : 'hide');
        });
}

function showCollapsed(html_id, disable_transitions)
{
    if (html_id[0] != '#') {
        html_id = '#' + html_id;
    }

    // Hack: If requested, temporarily disable transitions.  Bootstrap's default
    // transition is 0.35s, so we do just a bit longer.
    // Based on http://stackoverflow.com/a/22428493/25507
    if (disable_transitions) {
        $(html_id).addClass('disable-transition');
        setTimeout(function() { $(html_id).removeClass('disable-transition'); }, 400);
    }

    $(html_id).collapse('show');
    // Hack: Update "collapsed" class, since Bootstrap doesn't seem to do it
    // for us (unless, presumably, we use data-parent for full-blown accordion
    // behavior, and I don't really want to do that).
    $("[data-target=" + html_id + "]").removeClass('collapsed');
}

/**Gets the HTML IDs of currently expanded collapsed items. */
function getExpandedIds()
{
    return $.map($(".collapse.in"), function(n, i) {
        return n.id;
    });
}

function expandIds(id_list, disable_transitions)
{
    for (var i = 0; i < id_list.length; i++) {
        showCollapsed(id_list[i], disable_transitions);
    }
}

// List of collapsible IDs which are currently expanded, so that we can
// maintain expanded/collapsed state when switching versions.
var prev_expanded = null;

function updateFinished() {
    if (prev_expanded) {
        expandIds(prev_expanded, true);
        prev_expanded = null;
    }
}

function makeStickyHeader($header, $container)
{
    var header_top = $header.children('h1').offset().top;

    // Making the header sticky (fixed/absolute position) removes it from
    // layout, causing content to jump up.  To prevent this, create an empty
    // placeholder div that takes up the same space as the non-sticky
    // header.
    var $placeholder = $("<div class='sticky-placeholder'></div>").hide().css('height', $header.outerHeight(true) + 'px').insertAfter($header);

    $container.scroll(function() {
        if ($container.scrollTop() > header_top) {
            // Standard approach to sticky header is position: fixed.
            // That's hard to make work with our two-column, padding/margin
            // design, so manually set positioning instead.
            $header.addClass('sticky').css('top', $container.scrollTop() + 'px');
            $placeholder.show();
        } else {
            $header.removeClass('sticky').css('top', '');
            $placeholder.hide();
        }
    });
}

var options = {
    imgSize: 48
};

///Simplistic title-case function that capitalizes the beginning of every word.
function toTitleCase(s)
{
    var never_capitalize = {
        // Fix problems like "Berserker's"
        "s":true,
        // Prepositions and internal articles
        "of":true,
        "the":true
    };
    s = s.replace(/\b([a-z])([a-z]+)/g, function(match, p1, p2) { return never_capitalize[match] ? match : (p1.toUpperCase() + p2); });
    // Force the first word to be capitalized, even if it's "of" or "the"
    return s[0].toUpperCase() + s.slice(1);
}

///ToME-specific function that makes a ToME ID a valid and standard HTML ID
function toHtmlId(s)
{
    // For now, only replace characters known to cause issues.
    return s.toLowerCase().replace(/[':\/]/, '_');
}

///As toHtmlId, but leaves slashes intact, for code like talents that
///legitimately uses them (e.g., "spells/fire").
function toUnsafeHtmlId(s)
{
    return s.toLowerCase().replace(/[':]/, '_');
}

/**Given an object, return a new object that indexes the object's properties by
 * HTML ID.
 *
 * For example, if classes = { 'WARRIOR': { 'short_name': 'WARRIOR', ... }, ...},
 * then indexByHtmlId(classes, 'short_name') will return
 * { 'warrior': { 'short_name': 'WARRIOR', ... }, ...}
 */
function indexByHtmlId(obj, property) {
    return _.object(_.map(obj, function(elem) { return [ toHtmlId(elem[property]), elem ]; }));
}

/**Marks up inline links to the ToME wiki */
function markupHintLinks() {
    // TODO: Try FontAwesome instead. I think it might look nicer than glyphicon here.
    $('.hint-link[target!=_blank]').append(' <span class="fa fa-external-link"></span>')
        .attr('target', '_blank');
}

function enableTalentTooltips() {
    $(".html-tooltip").tooltip({ html: true });
    $(".variable, .talent-variable, .stat-variable")
        .attr('data-toggle', 'tooltip')
        .tooltip({ html: true });
}

Handlebars.registerHelper('tome_git_url', function() {
    return 'http://git.net-core.org/tome/t-engine4';
});

///Iterates over properties, sorted. Based on http://stackoverflow.com/a/9058854/25507.
Handlebars.registerHelper('eachProperty', function(context, options) {
    var ret = "",
        keys = _.keys(context || {});
    keys.sort();
    for (var i = 0; i < keys.length; i++) {
        ret = ret + options.fn({key: keys[i], value: context[keys[i]]});
    }
    return ret;
});

/**Renders a partial, with additional arguments. Based on http://stackoverflow.com/a/14618035/25507
 *
 * Usage: Arguments are merged with the context for rendering only
 * (non destructive). Use `:token` syntax to replace parts of the
 * template path. Tokens are replace in order.
 *
 * USAGE: {{$ 'path.to.partial' context=newContext foo='bar' }}
 * USAGE: {{$ 'path.:1.:2' replaceOne replaceTwo foo='bar' }}
 */
Handlebars.registerHelper('$', function (partial) {
    var values, opts, done, value, context;
    if (!partial) {
        console.error('No partial name given.');
    }
    values = Array.prototype.slice.call(arguments, 1);
    opts = values.pop().hash;
    while (!done) {
        value = values.pop();
        if (value) {
            partial = partial.replace(/:[^\.]+/, value);
        } else {
            done = true;
        }
    }
    partial = Handlebars.partials[partial];
    if (!partial) {
        return '';
    }
    context = _.extend({}, opts.context || this, _.omit(opts, 'context', 'fn', 'inverse'));
    return new Handlebars.SafeString(partial(context));
});

Handlebars.registerHelper('choose', function(context, options) {
  return options.fn(context[Math.floor(Math.random() * context.length)]);
});

Handlebars.registerHelper('toTitleCase', function(context, options) {
    return toTitleCase(context);
});

Handlebars.registerHelper('toLowerCase', function(context, options) {
    return context.toLowerCase();
});

Handlebars.registerHelper('toDecimal', function(context, places, options) {
   return context.toFixed(places || 2);
});

// ToME-specific functions that makes a ToME ID a valid and standard HTML ID
Handlebars.registerHelper('toHtmlId', toHtmlId);
Handlebars.registerHelper('toUnsafeHtmlId', toUnsafeHtmlId);

// ToME-specific function that tries to make a name or ID into a te4.org wiki page name
Handlebars.registerHelper('toWikiPage', function(context, options) {
   return toTitleCase(context).replace(' ', '_');
});

Handlebars.registerHelper('tag', function(context, options) {
    return getData().tag;
});

Handlebars.registerHelper('currentQuery', function(context, options) {
    return currentQuery();
});

Handlebars.registerHelper('opt', function(opt_name) {
    return options[opt_name];
});

Handlebars.registerHelper('labelForChangeType', function(type) {
    var css_class = { "changed": "info", "added": "success", "removed": "danger" },
        text = { "changed": "Changed", "added": "New", "removed": "Removed" };
    return '<span class="label label-' + css_class[type] + '">' + text[type] + ':</span>';
});

/* Displays an entry in a stat block.
 * @param value
 *   the internal value to process
 * @display
 *   how to display the value
 * @mult
 *   If -1, invert the comparison.  If 0, don't prepend with '+'.
 * @compare
 *   if value is > compare, then a bonus; if < compare, a penalty
 */
function stat(desc, value, display, mult, compare) {
    var internal_value = value * (mult || 1),
        value_html;
    display = display || (value >= 0 ? '+' + value : value);
    compare = (compare || 0) * (mult || 1);
    if (internal_value == compare) {
        value_html = '<span class="stat-neutral">' + display + '</span>';
    } else if (internal_value > compare) {
        value_html = '<span class="stat-bonus">' + display + '</span>';
    } else {
        value_html = '<span class="stat-penalty">' + display + '</span>';
    }
    return new Handlebars.SafeString("<dt>" + desc + ":</dt><dd>" + value_html + "</dd>");
}

Handlebars.registerHelper('stat', function(desc, value) {
    value = value || 0;
    return stat(desc, value);
});

Handlebars.registerHelper('customStat', function(desc, value, mult, compare) {
    return stat(desc, value, value, mult, compare);
});

Handlebars.registerHelper('percentStat', function(desc, value, mult, compare) {
    var percent = value * 100;
    percent = (mult && percent > 0 ? '+' : '') + percent.toFixed(0) + '%';
    return stat(desc, value, percent, mult, compare);
});

Handlebars.registerHelper('textStat', function(desc, value) {
    return new Handlebars.SafeString('<dt>' + desc + ':</dt><dd><span class="stat-neutral">' + value + '</span></dd>');
});

function configureImgSize() {
    options.imgSize = parseInt($.cookie("imgSize") || options.imgSize);

    function showImgSizeSelection() {
        $('.option-img-size').removeClass("selected");
        $('.option-img-size[data-img-size="' + options.imgSize + '"]').addClass("selected");
    }

    function changeImgSize(old_size, new_size) {
        $("img").each(function(n, e) {
            if ($(this).attr("width") == old_size) {
                $(this).attr("width", new_size)
                    .attr("height", new_size)
                    .attr("src", $(this).attr("src").replace(old_size.toString(), new_size.toString()));
            }
        });
    }

    showImgSizeSelection();

    $(".option-img-size").click(function(e) {
        var old_size = options.imgSize;
        options.imgSize = parseInt($(this).attr("data-img-size"));
        showImgSizeSelection();
        changeImgSize(old_size, options.imgSize);
        $.cookie('imgSize', options.imgSize, { expires: 365, path: '/' });
    });
}

var typeahead = (function() {
    var categories = [ 'races', 'classes', 'talents-types', 'talents' ];
    var category_header = {
        'races': 'Races',
        'classes': 'Classes',
        'talents-types': 'Talent Categories',
        'talents': 'Talents'
    };

    // Bloodhound search objects.  These are indexed by version number and have
    // subkeys for each data source.
    var search = {};

    function updateSearch(version) {
        if (search[version]) {
            return;
        }

        search[version] = {};
        for (var i = 0; i < categories.length; i++) {
            search[version][categories[i]] = new Bloodhound({
                datumTokenizer: Bloodhound.tokenizers.obj.nonword('name'),
                queryTokenizer: Bloodhound.tokenizers.nonword,
                limit: 10,
                prefetch: {
                    url: 'data/' + version + '/search.' + categories[i] + '.json',
                    thumbprint: VERSION
                }
            });

            // FIXME: Do this if we detect a version change
            //search[version][categories[i]].clearPrefetchCache();

            search[version][categories[i]].initialize();
        }
    }

    function initTypeahead(version) {
        var datasets = [];
        for (var i = 0; i < categories.length; i++) {
            datasets.push({
                name: version.replace(/\./g, '_') + '-' + categories[i],
                displayKey: 'name',
                source: search[version][categories[i]].ttAdapter(),
                templates: {
                    header: '<h4>' + category_header[categories[i]] + '</h4>',
                    suggestion: Handlebars.templates.search_suggestion
                }
            });
        }
        $('.typeahead').typeahead({ highlight: true, minLength: 1 }, datasets);
    }

    function updateTypeahead(version) {
        $('.typeahead').typeahead('destroy');
        initTypeahead(version);
    }

    return {
        init: function(version) {
            updateSearch(version);
            initTypeahead(version);
        },

        update: function(version) {
            updateSearch(version);
            updateTypeahead(version);
        },
    };
})();

// ToME versions.
var versions = (function() {
    var $_dropdown;

    // List of collapsible IDs which are currently expanded, so that we can
    // maintain expanded/collapsed state when switching versions.

    function onChange() {
        $_dropdown.val(versions.current);

        // Hack: If version changes, then save what IDs are expanded so
        // we can restore their state after we recreate them for the
        // new version, and also assume that the side nav needs to be
        // refreshed.  (This is a hack because it ties the versions
        // module too closely to our DOM organization.)
        prev_expanded = getExpandedIds();
        $("#side-nav").html("");

        updateNav();
        typeahead.update(versions.current);
    }

    var versions = {
        DEFAULT: '1.5.2',
        ALL: [ '1.1.5', '1.2.5', '1.3.3', '1.4.9', '1.5.0', '1.5.1', '1.5.2', 'master' ],
        DISPLAY: { 'master': 'next' },

        name: function(ver) {
            return versions.DISPLAY[ver] || ver;
        },

        isMajor: function(ver) {
            return ver.endsWith('.0');
        },

        asMajor: function(ver) {
            return ver.replace(/\.\d+$/, '');
        },

        update: function(query) {
            query = query || {};
            query.ver = query.ver || versions.DEFAULT;
            if (versions.current != query.ver) {
                versions.current = query.ver;
                onChange();
            }
        },

        asQuery: function() {
            if (versions.current == versions.DEFAULT) {
                return '';
            } else {
                return 'ver=' + versions.current;
            }
        },

        // Lists available versions in the given <option> element(s).
        list: function($el, $container) {
            var html;
            if (versions.ALL.length < 2) {
                ($container || $el).hide();
            } else {
                html = '';
                for (var i = 0; i < versions.ALL.length; i++) {
                    html += '<option value="' + versions.ALL[i] + '"';
                    if (versions.ALL[i] == versions.DEFAULT) {
                        html += ' selected';
                    }
                    html += '>' + versions.name(versions.ALL[i]) + '</option>';
                }
                ($container || $el).removeClass("hidden").show();
                $el.html(html);
            }
        },

        // Listens for version change events in the given <option> element(s).
        listen: function($el) {
            $el.change(function() {
                versions.current = $(this).val();
                onChange();
                hasher.setHash(locationHashNoQuery() + currentQuery());
            });
        },

        // If 'master' isn't shown, then redirect queries to current release.
        redirectMasterToDefault: function(new_hash, old_hash) {
            if (parseHashQueryString().ver == 'master') {
                hasher.replaceHash(locationHashNoQuery());
                return true;
            }
        },

        init: function($el, $container) {
            $_dropdown = $el;
            versions.list($el, $container);
            versions.listen($el);
            updateNav();
            typeahead.init(versions.current);
        }
    };
    versions.current = versions.DEFAULT;
    return versions;
}());

// talent masteries.
var masteries = (function() {
    var $_dropdown;

    function onChange() {
        $_dropdown.val(masteries.current);

        prev_expanded = getExpandedIds();
        $("#side-nav").html("");

        updateNav();
    }

    var masteries = {
        DEFAULT: '1.3',
        ALL: [ '0.8', '1.0', '1.1', '1.2', '1.3', '1.5' ],

        name: function(ver) {
            return ver;
        },

        update: function(query) {
            query = query || {};
            query.ver = query.mastery || versions.DEFAULT;
            if (masteries.current != query.mastery) {
                masteries.current = query.mastery;
                onChange();
            }
        },

        asQuery: function() {
            if (masteries.current == masteries.DEFAULT) {
                return '';
            } else {
                return 'mastery=' + masteries.current;
            }
        },

        // Lists available versions in the given <option> element(s).
        list: function($el, $container) {
            var html;
            if (masteries.ALL.length < 2) {
                ($container || $el).hide();
            } else {
                html = '';
                for (var i = 0; i < masteries.ALL.length; i++) {
                    html += '<option value="' + masteries.ALL[i] + '"';
                    if (masteries.ALL[i] == masteries.DEFAULT) {
                        html += ' selected';
                    }
                    html += '>' + masteries.name(masteries.ALL[i]) + '</option>';
                }
                ($container || $el).removeClass("hidden").show();
                $el.html(html);
            }
        },

        // Listens for change events in the given <option> element(s).
        listen: function($el) {
            $el.change(function() {
                masteries.current = $(this).val();
                onChange();
                hasher.setHash(locationHashNoQuery() + currentQuery());
            });
        },

        init: function($el, $container) {
            $_dropdown = $el;
            masteries.list($el, $container);
            masteries.listen($el);
            updateNav();
        }
    };
    masteries.current = masteries.DEFAULT;
    return masteries;
}());

var routes,
    load_nav_data_handler,
    base_title = document.title;

function initializeRoutes() {
    routes = {

        // Default route.
        default_route: crossroads.addRoute(':?query:', function(query) {
            versions.update(query);
            document.title = base_title;
            setActiveNav();

            $("#content").html($("#news").html());
            $("#side-nav").html('');
        }),

        // Updates for previous versions of the site.
        reroute1: crossroads.addRoute('changes/talents?ver=1.2.0dev', function() {
            hasher.replaceHash('changes/talents?ver=master');
        }),

        changes_talents: crossroads.addRoute('changes/talents:?query:', function(query) {
            routes.talents.matched.dispatch(query);

            $("#content-container").scrollTop(0);
            loadDataIfNeeded('changes.talents', function() {
                document.title += ' - New in ' + getData().majorVersion;
                $("#content").html(listChangesTalents(tome));

                enableTalentTooltips();
                updateFinished();
            });
        }),

        recent_changes_talents: crossroads.addRoute('recent-changes/talents:?query:', function(query) {
            // FIXME: Remove duplication with changes_talents route
            routes.talents.matched.dispatch(query);

            $("#content-container").scrollTop(0);
            loadDataIfNeeded('recent-changes.talents', function() {
                document.title += ' - New in ' + getData().version;
                $("#content").html(listRecentChangesTalents(tome));

                enableTalentTooltips();
                updateFinished();
            });
        }),

        talents: crossroads.addRoute('talents:?query:', function(query) {
            versions.update(query);
            document.title = base_title + ' - Talents';
            setActiveNav("#talents");

            if (!$("#nav-talents").length) {
                loadDataIfNeeded('', function() {
                    $("#side-nav").html(navTalents(tome));
                    load_nav_data_handler = loadNavTalents;
                    $("#content").html($("#news").html());
                });
            }
        }),

        talents_category: crossroads.addRoute("talents/{category}:?query:", function(category, query) {
            routes.talents.matched.dispatch(query);
            document.title += ' - ' + toTitleCase(category);

            $("#content-container").scrollTop(0);
            loadDataIfNeeded('talents.' + category, function() {
                var this_nav = "#nav-" + category;
                showCollapsed(this_nav);

                fillNavTalents(tome, category);
                $("#content").html(listTalents(tome, category));
                scrollToId();

                // Manually initialize .collapse; if we don't, then the first
                // click on Hide All will actually expand all.
                // See https://github.com/twbs/bootstrap/issues/5859
                $(".talent-details.collapse").collapse({toggle: false});

                enableTalentTooltips();

                fillTalentAvailability(tome, category);
                updateFinished();
            });
        }),

        talents_category_type: crossroads.addRoute("talents/{category}/{type}:?query:", function(category, type, query) {
            routes.talents_category.matched.dispatch(category, query);
        }),

        talents_category_type_id: crossroads.addRoute("talents/{category}/{type}/{talent_id}:?query:", function(category, type, talent_id, query) {
            // TODO: scrollToId not yet working for talent_id links, and talent_id links aren't yet published
            routes.talents_category.matched.dispatch(category, query);
        }),

        races: crossroads.addRoute('races:?query:', function(query) {
            versions.update(query);
            document.title += ' - Races';
            setActiveNav("#races");

            if (!$("#nav-races").length) {
                loadRacesIfNeeded(function() {
                    $("#side-nav").html(navRaces(tome));
                    load_nav_data_handler = false;
                    $("#content").html($("#news").html());
                });
            }
        }),

        races_race: crossroads.addRoute("races/{r}:?query:", function(r, query) {
            versions.update(query);

            loadRacesIfNeeded(function() {
                routes.races.matched.dispatch(query);

                var data = getData();
                if (!data.races.races_by_id[r]) {
                    handleUnknownRace(tome, r);
                    return;
                }

                document.title += ' - ' + data.races.races_by_id[r].display_name;

                $("#content-container").scrollTop(0);

                var this_nav = "#nav-" + r;
                showCollapsed(this_nav);

                $("#content").html(listRaces(tome, r));
                scrollToId();

                updateFinished();
            });
        }),

        races_race_subrace: crossroads.addRoute("races/{r}/{subrace}:?query:", function(r, subrace, query) {
            routes.races_race.matched.dispatch(r, query);
        }),

        classes: crossroads.addRoute('classes:?query:', function(query) {
            versions.update(query);
            document.title += ' - Classes';
            setActiveNav("#classes");

            if (!$("#nav-classes").length) {
                loadClassesIfNeeded(function() {
                    $("#side-nav").html(navClasses(tome));
                    load_nav_data_handler = false;
                    $("#content").html($("#news").html());
                });
            }
        }),

        classes_class: crossroads.addRoute("classes/{cls}:?query:", function(cls, query) {
            versions.update(query);

            loadClassesIfNeeded(function() {
                routes.classes.matched.dispatch(query);
                document.title += ' - ' + getData().classes.classes_by_id[cls].display_name;

                $("#content-container").scrollTop(0);

                var this_nav = "#nav-" + cls;
                showCollapsed(this_nav);

                $("#content").html(listClasses(tome, cls));
                scrollToId();

                fillClassTalents(tome, cls);

                updateFinished();
            });
        }),

        classes_class_subclass: crossroads.addRoute("classes/{cls}/{subclass}:?query:", function(cls, subclass, query) {
            routes.classes_class.matched.dispatch(cls, query);
        })
    };

    function parseHash(new_hash, old_hash) {
        if (!versions.redirectMasterToDefault()) {
            crossroads.parse(new_hash);
        }
    }

    hasher.prependHash = '';
    hasher.initialized.add(parseHash);
    hasher.changed.add(parseHash);
    if (googletag && googletag.pubads) hasher.changed.add(function() { googletag.pubads().refresh([ad_slot]) });
    hasher.init();
}

function loadData(data_file, success) {
    var url = "data/" + versions.current + "/" + data_file;
    // talent files include the mastery
    if (data_file.substr(0, 8) == 'talents.')
        url += '-' + ((masteries.current == '1.0') ? '1' : masteries.current);

    $.ajax({
        url: url + '.json',
        dataType: "json"
    }).success(success);
    // FIXME: Error handling
}

/**Handler for expanding nav items. Takes a jQuery element that's being
 * expanded and does any on-demand loading of the data for that nav item.
 */
load_nav_data_handler = false;

/**Loads a section of JSON data into the tome object if needed, then executes
 * the success function handler.
 *
 * For example, if data_file is "talents.chronomancy", then this function
 * loads talents_chronomancy.json to tome.talents.chronomancy then calls
 * success(tome.talents.chronomancy).
 */
function loadDataIfNeeded(data_file, success) {
    var parts, last_part, tome_part;

    // Special case: No data has been loaded at all.
    // Load top-level data, then reissue the request.
    if (!getData()) {
        loadData('tome', function(data) {
            data.hasMajorChanges = versions.asMajor(data.version) != versions.asMajor(versions.ALL[0]);
            data.hasMinorChanges = data.version != versions.ALL[0] &&
                !versions.isMajor(data.version) &&
                data.version != 'master';

            data.version = versions.name(data.version);
            data.majorVersion = versions.asMajor(data.version);

            data.fixups = {};

            tome[versions.current + '-' + masteries.current] = data;
            loadDataIfNeeded(data_file, success);
        });
        return;
    }

    // Special case: No data file requested.
    if (!data_file) {
        success(tome);
        return;
    }

    // General case: Walk the object tree to find where the requested file
    // should go, and load it.
    parts = data_file.split(".");
    last_part = parts.pop();
    tome_part = getData();

    for (var i = 0; i < parts.length; i++) {
        if (typeof(tome_part[parts[i]]) === 'undefined') {
            tome_part[parts[i]] = {};
        }
        tome_part = tome_part[parts[i]];
    }

    if (!tome_part[last_part]) {
        loadData(data_file, function(data) {
            tome_part[last_part] = data;
            success(data);
        });
    } else {
        success(tome_part[last_part]);
    }
}

window.onerror = function(msg, url, line) {
    $("html").removeClass("wait");

    if ($("#content").html() === 'Loading...') {
        $("#content").html('');
    }

    $("#content").prepend(
        '<div class="alert alert-danger">' +
            'Internal error: ' + escapeHtml(msg || '') +
            ' on ' + url + ' line ' + line +
            '<button type="button" class="close" data-dismiss="alert"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>'  +
        '</div>'
    );
};

$(function() {
    // See http://stackoverflow.com/a/10801889/25507
    $(document).ajaxStart(function() { $("html").addClass("wait"); });
    $(document).ajaxStop(function() { $("html").removeClass("wait"); });

    $("#side-nav-container .page-header").height($("#content-header").height());

    // Clicking on a ".clickable" element triggers the <a> within it.
    $("html").on("click", ".clickable", function(e) {
        if (e.target.nodeName == 'A') {
            // If the user clicked on the link itself, then simply let
            // the browser handle it.
            return true;
        }

        $(this).find('a').click();
    });

    // Hack: Clicking the expand / collapse within an <a> doesn't trigger the <a>.
    $("#side-nav").on("click", ".dropdown", function(e) {
        e.preventDefault();
    });

    $("#side-nav").on("shown.bs.collapse", ".collapse", function(e) {
        if (load_nav_data_handler) {
            load_nav_data_handler($(this));
        }
    });

    $("html").on("error", "img", function() {
        $(this).hide();
    });

    makeStickyHeader($("#content-header"), $("#content-container"));
    enableExpandCollapseAll();
    versions.init($(".ver-dropdown"), $(".ver-dropdown-container"));
    masteries.init($(".mastery-dropdown"), $(".mastery-dropdown-container"));
    configureImgSize();
    $('.tt-dropdown-menu').width($('#content-header .header-tools').width());

    // Track Google Analytics as we navigate from one subpage / hash link to another.
    // Based on http://stackoverflow.com/a/4813223/25507
    // Really old browsers don't support hashchange.  A plugin is available, but I don't really care right now.
    $(window).on('hashchange', function() {
        _gaq.push(['_trackPageview', location.pathname + location.search + location.hash]);
    });

    // We explicitly do NOT use var, for now, to facilitate inspection in Firebug.
    // (Our route handlers and such currently also rely on tome being global.)
    tome = {};

    initializeRoutes();
});
