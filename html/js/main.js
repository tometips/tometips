function scrollToId()
{
    var $hash = $(location.hash.replace(/\//g, '\\/'));
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
    return tome[current_version].tag;
});

// See http://stackoverflow.com/a/92819/25507
function talentImgError(image) {
    image.onerror = "";
    image.src = "img/000000-0.png";
    return true;
}

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
                            '<img width="64" height="64" src="img/talents/{{#if image}}{{image}}{{else}}{{toLowerCase short_name}}.png{{/if}}" onerror="talentImgError(this)">' + '{{name}}' +
                        '</a>' +
                    '</h3>' +
                '</div>' +
                '<div id="collapse-{{toHtmlId id}}" class="talent-details panel-collapse collapse">' +
                    '<div class="panel-body">' +
                        "<dl>" +
                            "{{#if mode}}<dt>Use Mode</dt><dd>{{mode}}</dd>{{/if}}" +
                            "{{#if cost}}<dt>Cost</dt><dd>{{{cost}}}</dd>{{/if}}" +
                            "{{#if range}}<dt>Range</dt><dd>{{{range}}}</dd>{{/if}}" +
                            "{{#if cooldown}}<dt>Cooldown</dt><dd>{{{cooldown}}}</dd>{{/if}}" +
                            "{{#if use_speed}}<dt>Use Speed</dt><dd>{{use_speed}}</dd>{{/if}}" +
                            '{{#if info_text}}<dt class="multiline-dd">Description</dt><dd>{{{info_text}}}</dd>{{/if}}' +
                        '</dl>' +
                        '{{#if source_code}}<div class="source-link"><a href="http://git.net-core.org/darkgod/t-engine4/blob/{{tag}}/game/modules/tome/{{source_code.[0]}}#L{{source_code.[1]}}" target="_blank">View source</a></div>{{/if}}' +
                    '</div>' +
                '</div>' +
            '</div>' +
        "{{/each}}</div></div>" +
    "{{/each}}"
);

var talent_by_type_nav_template = Handlebars.compile(
    '<ul class="nav">{{#each talent_categories}}' +
        '<li><a href="#talents/{{toHtmlId this}}"><span data-toggle="collapse" data-target="#nav-{{toHtmlId this}}" class="dropdown collapsed"></span>{{toTitleCase this}}</a>' +
        '<ul class="nav collapse" id="nav-{{toHtmlId this}}">' +
        // Empty for now; will be populated later
        "</ul></li>" +
    "{{/each}}</ul>"
);

function navTalents(tome) {
    return talent_by_type_nav_template(tome[current_version]);
}

function fillNavTalents(tome, category) {
    var $el = $("#nav-" + category),
        talent_types = tome[current_version].talents[category];
    if ($.trim($el.html())) {
        // Nav already exists; no need to do more.
        return;
    }

    for (var i = 0; i < talent_types.length; i++) {
        $el.append('<li><a href="#talents/' + toHtmlId(talent_types[i].type) + '">' + toTitleCase(talent_types[i].name + '</a></li>'));
        // "type" happens to be category/name, which is what we want for routing
    }
}

function listTalents(tome, category) {
    return talent_by_type_template(tome[current_version].talents[category]);
}

function initializeRoutes() {
    // ToME versions.
    DEFAULT_VERSION = '1.1.5';
    current_version = DEFAULT_VERSION;
    Finch.observe('ver', function(new_version) {
        new_version = new_version || DEFAULT_VERSION;
        if (new_version != current_version) {
            current_version = new_version;
        }
    });

    // Default route.  We currently just have talents.
    Finch.route("", function() {
        Finch.navigate("talents", true);
    });

    Finch.route("talents", function() {
        loadDataIfNeeded('', function() {
            $("#side-nav").html(navTalents(tome));
            $("#content").html("Select a talent category to the left.");
        });
    });

    Finch.route("[talents]/:category", function(bindings) {
        $("#content-container").scrollTop(0);
        loadDataIfNeeded('talents.' + bindings.category, function() {
            var this_nav = "#nav-" + bindings.category;
            $(this_nav).collapse('show');
            // Hack: Update "collapsed" class, since Bootstrap doesn't seem to do it for us
            // (unless, presumably, we use data-parent for full-blown accordion behavior,
            // and I don't really want to do that).
            $("[data-target=" + this_nav + "]").removeClass('collapsed');

            fillNavTalents(tome, bindings.category);
            $("#content").html(listTalents(tome, bindings.category));
            scrollToId();
        });
    });

    Finch.route("[talents/:category]/:type", function(bindings) {
        $("#collapse-" + bindings.type).collapse("show");
    });

    Finch.listen();
}

function loadData(data_file, success) {
    $.ajax({
        url: "data/" + current_version + "/" + data_file + ".json",
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
    if (!tome[current_version]) {
        loading_version = current_version;
        loadData('tome', function(data) {
            tome[loading_version] = data;
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
    tome_part = tome[current_version];

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

