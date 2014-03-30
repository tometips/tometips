///Simplistic title-case function that capitalizes the beginning of every word.
function toTitleCase(s)
{
    // FIXME: Handle "of"
    return s.replace(/\b[a-z]/g, function(match) { return match.toUpperCase(); });
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
    // For now, only replace characters known to cause issues.
    return context.toLowerCase().replace(':', '_');
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
        '<h2 id="talents/{{type}}">{{toTitleCase name}}</h2><div>' +
        '<p>{{description}}</p><div>' +
        "{{#each talents}}" +
            '<div class="panel panel-default">' +
                '<div class="panel-heading clickable">' +
                    '<h3 class="panel-title">' +
                        '<a data-toggle="collapse" data-target="#collapse-{{toHtmlId short_name}}">' +
                            '<img width="64" height="64" src="img/talents/{{#if image}}{{image}}{{else}}{{toLowerCase short_name}}.png{{/if}}" onerror="talentImgError(this)">' + '{{name}}' +
                        '</a>' +
                    '</h3>' +
                '</div>' +
                '<div id="collapse-{{toHtmlId short_name}}" class="talent-details panel-collapse collapse">' +
                    '<div class="panel-body">' +
                        "<dl>" +
                            "{{#if mode}}<dt>Use Mode</dt><dd>{{mode}}</dd>{{/if}}" +
                            "{{#if cost}}<dt>Cost</dt><dd>{{{cost}}}</dd>{{/if}}" +
                            "{{#if range}}<dt>Range</dt><dd>{{{range}}}</dd>{{/if}}" +
                            "{{#if cooldown}}<dt>Cooldown</dt><dd>{{{cooldown}}}</dd>{{/if}}" +
                            "{{#if use_speed}}<dt>Use Speed</dt><dd>{{use_speed}}</dd>{{/if}}" +
                            '{{#if info_text}}<dt class="multiline-dd">Description</dt><dd>{{{info_text}}}</dd>{{/if}}' +
                        '</dl>' +
                    '</div>' +
                '</div>' +
            '</div>' +
        "{{/each}}</div></div>" +
    "{{/each}}"
);

var talent_by_type_nav_template = Handlebars.compile(
    '<ul class="nav">{{#each talent_categories}}' +
        '<li><a href="#talents/{{this}}" data-toggle="collapse" data-target="#nav-{{this}}" class="collapsed">{{toTitleCase this}}</a>' +
        '<ul class="nav collapse" id="nav-{{this}}">' +
        // Empty for now; will be populated later
        "</ul></li>" +
    "{{/each}}</ul>"
);

function navTalents(tome) {
    return talent_by_type_nav_template(tome);
}

function fillNavTalents(tome, category) {
    var $el = $("#nav-" + category),
        talent_types = tome.talents[category];
    if ($.trim($el.html())) {
        // Nav already exists; no need to do more.
        return;
    }

    for (var i = 0; i < talent_types.length; i++) {
        $el.append('<li><a href="#talents/' + talent_types[i].type + '">' + toTitleCase(talent_types[i].name + '</a></li>'));
        // "type" happens to be category/name, which is what we want for routing
    }
}

function listTalents(tome, category) {
    return talent_by_type_template(tome.talents[category]);
}

function initializeRoutes() {
    // Default route.  We currently just have talents.
    Finch.route("", function() {
        Finch.navigate("talents");
    });

    Finch.route("talents", function() {
        $("#side-nav").html(navTalents(tome));
        $("#content").html("Select a talent category to the left.");
    });

    Finch.route("[talents]/:category", function(bindings) {
        loadDataIfNeeded('talents.' + bindings.category, function() {
            fillNavTalents(tome, bindings.category);
            $("#content").html(listTalents(tome, bindings.category));
        });
    });

    Finch.route("[talents/:category]/:type", function(bindings) {
        $("#collapse-" + bindings.type).collapse("show");
    });

    Finch.listen();
}

function loadData(data_file, success) {
    $.ajax({
        url: "data/" + data_file + ".json",
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
    var parts = data_file.split("."),
        last_part = parts.pop(),
        tome_part = tome;

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
    $("html").on("click", ".clickable", function(e) {
        if (e.target.nodeName == 'A') {
            // If the user clicked on the link itself, then simply let
            // the browser handle it.
            return true;
        }

        $(this).find('a').click();
    });

    $("html").on("error", "img", function() {
        $(this).hide();
    });

    // We explicitly do NOT use var, for now, to facilitate inspection in Firebug.
    // (Our route handlers and loading routes also rely on tome being global.)
    tome = {};
    loadData('tome', function(data) {
        tome = data;
        initializeRoutes();
    });
});

