///Simplistic title-case function that capitalizes the beginning of every word.
function toTitleCase(s)
{
    // FIXME: Handle "of"
    return s.replace(/\b[a-z]/g, function(match) { return match.toUpperCase(); });
}

Handlebars.registerHelper('eachProperty', function(context, options) {
    var ret = "";
    for(var prop in context)
    {
        ret = ret + options.fn({property:prop,value:context[prop]});
    }
    return ret;
});

Handlebars.registerHelper('toTitleCase', function(context, options) {
    return toTitleCase(context);
});

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
    "{{#eachProperty talentsByCategory}}" +
        '<h1>{{toTitleCase property}}</h1><div class="sub-accordion">' +
        "{{#each value}}" +
            '<h2>{{toTitleCase name}}</h2><div>' +
            '<p>{{description}}</p><div class="sub-accordion">' +
            "{{#each talents}}" +
                '<h3>{{name}}</h3><div class="talent-details">' +
                "<dl>" +
                "{{#if mode}}<dt>Use Mode</dt><dd>{{mode}}</dd>{{/if}}" +
                "{{#if cost}}<dt>Cost</dt><dd>{{{cost}}}</dd>{{/if}}" +
                "{{#if range}}<dt>Range</dt><dd>{{{range}}}</dd>{{/if}}" +
                "{{#if cooldown}}<dt>Cooldown</dt><dd>{{{cooldown}}}</dd>{{/if}}" +
                "{{#if use_speed}}<dt>Use Speed</dt><dd>{{use_speed}}</dd>{{/if}}" +
                "{{#if info_text}}<dt>Description</dt><dd>{{info_text}}</dd>{{/if}}" +
                "</dl></div>" +
            "{{/each}}</div></div>" +
        "{{/each}}</div>" +
    "{{/eachProperty}}"
);

function list_talents(tome, tomex) {
    return talent_by_type_template(tomex);
}

$(document).ready(function() {
    // We explicitly do NOT use var, for now, to facilitate inspection in Firebug.
    tomex = {};
    process_spoilers(tome, tomex);
    $("#content").html(list_talents(tome, tomex));
    $(".sub-accordion").accordion({active: false, collapsible: true, heightStyle: "content" });
    $("#content").accordion({active: false, collapsible: true, heightStyle: "content" });
});

