///Simplistic title-case function that capitalizes the beginning of every word.
function toTitleCase(s)
{
    return s.replace(/\b[a-z]/g, function(match) { return match.toUpperCase(); });
}

/**Does additional processing to the raw spoilers (in tome) and stores the
 * processing results to tomex.
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
        tomex.talentsByCategory[category].push(talent_types[i]);
    }
}

function list_talents(tome, tomex) {
    // FIXME: Escape HTML throughout (or switch to a templating language)
    var html = "",
        category,
        type;
    for (category in tomex.talentsByCategory) {
        if (!tomex.talentsByCategory.hasOwnProperty(category)) {
            continue;
        }
        html += '<h1>' + toTitleCase(category) + '</h1>';
        for (var i = 0; i < tomex.talentsByCategory[category].length; i++) {
            type = tomex.talentsByCategory[category][i];
            html += '<h2>' + toTitleCase(tome.talents_types_def[type].name) + '</h2>' +
                '<p>' + tome.talents_types_def[type].description + '</p>';
        }
    }
    return html;
}

$(document).ready(function() {
    // We explicitly do NOT use var, for now, to facilitate inspection in Firebug.
    tomex = {};
    process_spoilers(tome, tomex);
    $("#content").html(list_talents(tome, tomex));
});

