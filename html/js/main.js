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

// See http://stackoverflow.com/a/92819/25507
function talentImgError(image) {
    image.onerror = "";
    image.src = "img/000000-0.png";
    return true;
}

/**Does additional processing to the raw spoilers (in tome) and stores the
 * results to tomex.
 */
function process_spoilers(tome, tomex) {
    // FIXME: Polyfill for Object.keys
    var talent_types = Object.keys(tome.talents_types_def),
        category;
    talent_types.sort();
    tomex.talentsByCategory = {};
    for (var i = 0; i < talent_types.length; i++) {
        category = talent_types[i].split("/")[0];
        tomex.talentsByCategory[category] = tomex.talentsByCategory[category] || []; 
        for (var j = 0; j < tome.talents_types_def[talent_types[i]].length; j++) {
            tome.talents_types_def[talent_types[i]][j].sort(function(a, b) {
                return a.type[1] < b.type[1] ||
                    (a.type[1] == b.type[1] && a.name < b.name);
            });
        }
        tomex.talentsByCategory[category].push(tome.talents_types_def[talent_types[i]]);
    }
}

var talent_by_type_template = Handlebars.compile(
    // FIXME: type header and description
    "{{#each this}}" +
        '<h2 id="talents/{{type}}">{{toTitleCase name}}</h2><div>' +
        '<p>{{description}}</p><div class="sub-accordion">' +
        "{{#each talents}}" +
            '<div class="panel panel-default">' +
                '<div class="panel-heading clickable">' +
                    '<h3 class="panel-title">' +
                        '<a data-toggle="collapse" data-target="#collapse-{{toLowerCase short_name}}">' +
                            '<img width="64" height="64" src="img/talents/{{#if image}}{{image}}{{else}}{{toLowerCase short_name}}.png{{/if}}" onerror="talentImgError(this)">' + '{{name}}' +
                        '</a>' +
                    '</h3>' +
                '</div>' +
                '<div id="collapse-{{toLowerCase short_name}}" class="talent-details panel-collapse collapse">' +
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
    '<ul class="nav">{{#eachProperty talentsByCategory}}' +
        '<li><a href="#talents/{{property}}" data-toggle="collapse" data-target="#nav-{{property}}">{{toTitleCase property}}</a>' +
        '<ul class="nav collapse" id="nav-{{property}}">' +
        '{{#each value}}' +
            '<li><a href="#talents/{{type}}">{{toTitleCase name}}</a></li>' +  // "type" happens to be category/name, which is what we want for routing
        "{{/each}}" +
        "</ul></li>" +
    "{{/eachProperty}}</ul>"
);

function nav_talents(tome, tomex) {
    return talent_by_type_nav_template(tomex);
}

function list_talents(tome, tomex, category) {
    // FIXME: Error handling for bad category - also check Sher'tul
    return talent_by_type_template(tomex.talentsByCategory[category]);
}

$(function() {
    // We explicitly do NOT use var, for now, to facilitate inspection in Firebug.
    tomex = {};
    process_spoilers(tome, tomex);

    // Default route.  We currently just have talents.
    Finch.route("", function() {
        Finch.navigate("talents");
    });

    Finch.route("talents", function() {
        $("#side-nav").html(nav_talents(tome, tomex));
        $("#content").html("Select a talent category to the left.");
    });

    Finch.route("[talents]/:category", function(bindings) {
        $("#content").html(list_talents(tome, tomex, bindings.category));
    });

    Finch.route("[talents/:category]/:type", function(bindings) {
        $("#collapse-" + bindings.type).collapse("show");
    });

    $(".sub-accordion").accordion({active: false, collapsible: true, heightStyle: "content" });
    //$("#content").accordion({active: false, collapsible: true, heightStyle: "content" });

    $("html").on("click", ".clickable", function(e) {
        if (e.target.nodeName == 'A') {
            // If the user clicked on the link itself, then simply let
            // the browser handle it.
            return true;
        }

        $(this).find('a').click();
    });

    $("html").on("error", "img", function() {
        alert("oh");
        $(this).hide();
    });

    Finch.listen();
});

