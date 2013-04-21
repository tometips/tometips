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
        tomex.talentsByCategory[category].push(tome.talents_types_def[talent_types[i]]);
    }
}

var talent_by_type_template = Handlebars.compile(
    "{{#eachProperty talentsByCategory}}" +
    "<h1>{{toTitleCase property}}</h1>" +
    "{{#each value}}" +
    "<h2>{{toTitleCase name}}</h2>" +
    "<p>{{description}}</p>" +
    "{{/each}}" +
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
});

