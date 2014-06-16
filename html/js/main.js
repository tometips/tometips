function locationHashNoQuery()
{
    return location.hash.replace(/\?.*/, '');
}

function currentQuery()
{
    var query = '';
    query += versions.asQuery();
    if (query) {
        return '?' + query;
    } else {
        return '';
    }
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
    $(".expand-all").addClass('glyphicon-collapse-down')
        .attr('title', 'Expand All');
    $(".collapse-all").addClass('glyphicon-collapse-up')
        .attr('title', 'Collapse All');
    $(".expand-all, .collapse-all").addClass('glyphicon clickable')
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

function makeStickyHeader($header, $container)
{
    var $sticky = $header.clone();
    $sticky.attr('id', $header.attr('id') + '-sticky')
        .addClass('sticky')
        .css('width', $header.width())
        .hide()
        .insertBefore($header);
    $container.scroll(function() {
        // Generic approach.  Lets the full header skip up a bit before the sticky header appears.
        //if ($container.scrollTop() >= $sticky.outerHeight())
        if ($header.children('h1').offset().top < $sticky.children('h1').offset().top) {
            $sticky.show();
            $header.css('visibility', 'hidden');
        } else {
            $sticky.hide();
            $header.css('visibility', '');
        }
    });
    $(window).resize(function() {
        $sticky.css('width', $header.width());
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
    return s.toLowerCase().replace(/[':]/, '_');
}

Handlebars.registerHelper('eachProperty', function(context, options) {
    var ret = "";
    for (var prop in context) {
        ret = ret + options.fn({property:prop,value:context[prop]});
    }
    return ret;
});

Handlebars.registerHelper('toTitleCase', function(context, options) {
    return toTitleCase(context);
});

Handlebars.registerHelper('toLowerCase', function(context, options) {
    return context.toLowerCase();
});

// ToME-specific function that makes a ToME ID a valid and standard HTML ID
Handlebars.registerHelper('toHtmlId', function(context, options) {
    return toHtmlId(context);
});

Handlebars.registerHelper('tag', function(context, options) {
    return tome[versions.current].tag;
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

// See http://stackoverflow.com/a/92819/25507
function talentImgError(image) {
    image.onerror = "";
    image.src = "img/000000-0.png";
    return true;
}

var talent_img = Handlebars.registerPartial("talent_img",
    '<img width="{{opt "imgSize"}}" height="{{opt "imgSize"}}" src="img/talents/{{opt "imgSize"}}/{{#if image}}{{image}}{{else}}{{toLowerCase short_name}}.png{{/if}}" onerror="talentImgError(this)">'
);

var talent_details = Handlebars.registerPartial("talent",
    "<dl>" +
        "{{#if require}}<dt>Requirements</dt><dd>{{require}}</dd>{{/if}}" +
        "{{#if mode}}<dt>Use Mode</dt><dd>{{mode}}</dd>{{/if}}" +
        "{{#if cost}}<dt>Cost</dt><dd>{{{cost}}}</dd>{{/if}}" +
        "{{#if range}}<dt>Range</dt><dd>{{{range}}}</dd>{{/if}}" +
        "{{#if cooldown}}<dt>Cooldown</dt><dd>{{{cooldown}}}</dd>{{/if}}" +
        "{{#if use_speed}}<dt>Use Speed</dt><dd>{{use_speed}}</dd>{{/if}}" +
        '{{#if info_text}}<dt class="multiline-dd">Description</dt><dd>{{{info_text}}}</dd>{{/if}}' +
    '</dl>'
);

var talent_by_type_template = Handlebars.compile(
    // FIXME: type header and description
    "{{#each this}}" +
        '<h2><a class="anchor" id="talents/{{type}}"></a>{{toTitleCase name}}</h2><div>' +
        '<p>{{description}}</p><div>' +
        "{{#each talents}}" +
            '<div class="panel panel-default">' +
                '<div class="panel-heading clickable">' +
                    '<h3 class="panel-title">' +
                        '<a data-toggle="collapse" data-target="#collapse-{{toHtmlId id}}">' +
                            '{{> talent_img}}{{name}}' +
                        '</a>' +
                    '</h3>' +
                '</div>' +
                '<div id="collapse-{{toHtmlId id}}" class="talent-details panel-collapse collapse">' +
                    '<div class="panel-body">' +
                        '{{> talent}}' +
                        '{{#if source_code}}<div class="source-link"><a href="http://git.net-core.org/darkgod/t-engine4/blob/{{tag}}/game/modules/tome/{{source_code.[0]}}#L{{source_code.[1]}}" target="_blank">View source</a></div>{{/if}}' +
                    '</div>' +
                '</div>' +
            '</div>' +
        "{{/each}}</div></div>" +
    "{{/each}}"
);

var talent_by_type_nav_template = Handlebars.compile(
    '<ul id="nav-talents" class="nav">' +
    '{{#if has_changes}}' +
        '<li><a href="#changes/talents{{currentQuery}}"><span class="no-dropdown"></span>New in {{version_for_changes}}</a></li>' +
    '{{/if}}' +
    '{{#each talent_categories}}' +
        '<li><a href="#talents/{{toHtmlId this}}{{currentQuery}}"><span data-toggle="collapse" data-target="#nav-{{toHtmlId this}}" class="dropdown collapsed"></span>{{toTitleCase this}}</a>' +
        '<ul class="nav collapse" id="nav-{{toHtmlId this}}">' +
        // Empty for now; will be populated later
        "</ul></li>" +
    "{{/each}}</ul>"
);

var changes_talents_template = Handlebars.compile(
    "{{#each this}}" +
        '<h3><a class="anchor" id="changes/talents/{{name}}"></a>{{toTitleCase name}}</h3><div>' +
        "{{#each values}}" +
            '<div class="panel panel-default">' +
                '<div class="panel-heading clickable">' +
                    '<h3 class="panel-title">' +
                        '<a data-toggle="collapse" data-target="#collapse-{{type}}-{{toHtmlId value.id}}">' +
                            '{{> talent_img value}}{{{labelForChangeType type}}} {{value.name}}' +
                        '</a>' +
                    '</h3>' +
                '</div>' +
                '<div id="collapse-{{type}}-{{toHtmlId value.id}}" class="talent-details panel-collapse collapse">' +
                        '{{#if value2}}' +
                            '<table class="table table-bordered old-new">' +
                                '<colgroup>' +
                                    '<col width="50%">' +
                                    '<col width="50%">' +
                                '</colgroup>' +
                                '<tr><th>Old</th><th>New</th></tr><tr>' +
                                    '<td>{{> talent value2}}</td>' +
                                    '<td>{{> talent value}}</td>' +
                                '</tr>' +
                            '</table>' +
                        '{{else}}' + 
                            '<div class="panel-body">' +
                                '{{> talent value}}' +
                            '</div>' +
                        '{{/if}}' +
                '</div>' +
            '</div>' +
        "{{/each}}</div></div>" +
    "{{/each}}"
);

function navTalents(tome) {
    return talent_by_type_nav_template(tome[versions.current]);
}

function fillNavTalents(tome, category) {
    var $el = $("#nav-" + category),
        talent_types = tome[versions.current].talents[category];
    if ($.trim($el.html())) {
        // Nav already exists; no need to do more.
        return;
    }

    for (var i = 0; i < talent_types.length; i++) {
        $el.append('<li><a href="#talents/' + toHtmlId(talent_types[i].type) + currentQuery() + '">' + toTitleCase(talent_types[i].name + '</a></li>'));
        // "type" happens to be category/name, which is what we want for routing
    }
}

function listTalents(tome, category) {
    return talent_by_type_template(tome[versions.current].talents[category]);
}

function listChangesTalents(tome) {
    return changes_talents_template(tome[versions.current].changes.talents);
}

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

// ToME versions.
var versions = (function() {
    var $_dropdown,
        prev_expanded;

    function onChange() {
        $_dropdown.val(versions.current);

        // Hack: If version changes, then save what IDs are expanded so
        // we can restore their state after we recreate them for the
        // new version, and also assume that the side nav needs to be
        // refreshed.  (This is a hack because it ties the versions
        // module too closely to our DOM organization.)
        prev_expanded = getExpandedIds();
        $("#side-nav").html("");
    }

    var versions = {
        DEFAULT: '1.2.2',
        current: '1.2.2',
        ALL: [ '1.1.5', '1.2.2' ],
        DISPLAY: {}, //{ 'master': '1.2.2dev' },

        name: function(ver) {
            return versions.DISPLAY[ver] || ver;
        },

        // Version display for "New in 1.x.y" in particular
        DISPLAY_FOR_CHANGES: { '1.2.1': '1.2' },
        name_for_changes: function(ver) {
            return versions.DISPLAY_FOR_CHANGES[ver] || ver;
        },

        update: function(query) {
            query = query || {};
            query.ver = query.ver || versions.DEFAULT;
            if (versions.current != query.ver) {
                versions.current = query.ver;
                onChange();
            }
        },

        updateFinished: function() {
            if (prev_expanded) {
                expandIds(prev_expanded, true);
                prev_expanded = null;
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

        init: function($el, $container) {
            $_dropdown = $el;
            versions.list($el, $container);
            versions.listen($el);
        }
    };
    return versions;
}());

var routes;

function initializeRoutes() {
    routes = {

        // Default route.  We currently just have talents.
        default_route: crossroads.addRoute('', function() {
            hasher.replaceHash('talents');
        }),

        // Updates for previous versions of the site.
        reroute1: crossroads.addRoute('changes/talents?ver=1.2.0dev', function() {
            hasher.replaceHash('changes/talents?ver=master');
        }),

        changes_talents: crossroads.addRoute('changes/talents:?query:', function(query) {
            routes.talents.matched.dispatch(query);

            $("#content-container").scrollTop(0);
            loadDataIfNeeded('changes.talents', function() {
                $("#content").html(listChangesTalents(tome));

                versions.updateFinished();
            });
        }),

        talents: crossroads.addRoute('talents:?query:', function(query) {
            versions.update(query);

            if (!$("#nav-talents").length) {
                loadDataIfNeeded('', function() {
                    $("#side-nav").html(navTalents(tome));
                    $("#content").html("Select a talent category to the left.");
                });
            }
        }),

        talents_category: crossroads.addRoute("talents/{category}:?query:", function(category, query) {
            routes.talents.matched.dispatch(query);

            $("#content-container").scrollTop(0);
            loadDataIfNeeded('talents.' + category, function() {
                var this_nav = "#nav-" + category;
                showCollapsed(this_nav);

                fillNavTalents(tome, category);
                $("#content").html(listTalents(tome, category));
                scrollToId();

                versions.updateFinished();
            });
        }),

        talents_category_type: crossroads.addRoute("talents/{category}/{type}:?query:", function(category, type, query) {
            routes.talents_category.matched.dispatch(category, query);

            $("#collapse-" + type).collapse("show");
        })

    }

    function parseHash(new_hash, old_hash) {
         crossroads.parse(new_hash);
    }

    hasher.prependHash = '';
    hasher.initialized.add(parseHash);
    hasher.changed.add(parseHash);
    hasher.init();
}

function loadData(data_file, success) {
    $.ajax({
        url: "data/" + versions.current + "/" + data_file + ".json",
        dataType: "json"
    }).success(success);
    // FIXME: Error handling
}

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
    if (!tome[versions.current]) {
        loadData('tome', function(data) {
            data.version = versions.name(data.version);
            data.version_for_changes = versions.name_for_changes(data.version);
            tome[versions.current] = data;
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
    tome_part = tome[versions.current];

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

$(function() {
    // See http://stackoverflow.com/a/10801889/25507
    $(document).ajaxStart(function() { $("html").addClass("wait"); });
    $(document).ajaxStop(function() { $("html").removeClass("wait"); });

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
       var category = $(this).attr('id').replace('nav-', '');
       loadDataIfNeeded('talents.' + category, function() {
            fillNavTalents(tome, category);
        });
    });

    $("html").on("error", "img", function() {
        $(this).hide();
    });

    makeStickyHeader($("#content-header"), $("#content-container"));
    enableExpandCollapseAll();
    versions.init($(".ver-dropdown"), $(".ver-dropdown-container"));
    configureImgSize();

    // Track Google Analytics as we navigate from one subpage / hash link to another.
    // Based on http://stackoverflow.com/a/4813223/25507
    // Really old browsers don't support hashchange.  A plugin is available, but I don't really care right now.
    $(window).on('hashchange', function() {
        _gaq.push(['_trackPageview', location.pathname + location.search + location.hash]);
    })

    // We explicitly do NOT use var, for now, to facilitate inspection in Firebug.
    // (Our route handlers and such currently also rely on tome being global.)
    tome = {};

    initializeRoutes();
});

