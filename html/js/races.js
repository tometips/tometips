function fixupRaces(tome) {
    var data = getData();
    var r = data.races;

    if (data.fixups.races) {
        return;
    }

    // Replace IDs in race_list with references to the actual race definition.
    r.race_list = _.map(r.race_list, function(race) { return r.races[race]; });

    // Process subraces, and store a reference from each subrace back to the
    // race ID.
    _.each(r.races, function(elem) {
        _.each(elem.subrace_list, function (sub) {
            var exp_penalty = r.subraces[sub].experience;
            exp_penalty = (exp_penalty || 1.0) - 1.0;
            if (!r.subraces[sub].images || !r.subraces[sub].images.length) {
                r.subraces[sub].images = [
                    { file: 'player/' + sub.toLowerCase() + '_male.png' },
                    { file: 'player/' + sub.toLowerCase() + '_female.png' }
                ];
            }
            r.subraces[sub].exp_penalty = exp_penalty;
            r.subraces[sub].race_short_name = elem.short_name;
        });
    });

    // Replace subrace IDs in each race's subrace_list with references
    // to the actual subrace definition.
    _.each(r.races, function(elem) {
        elem.subrace_list = _.map(elem.subrace_list, function(sub) { return r.subraces[sub]; });
        elem.single_subrace = elem.subrace_list.length == 1;
    });

    r.races_by_id = indexByHtmlId(r.races, 'short_name');

    data.fixups.races = true;
}

function navRaces(tome) {
    return Handlebars.templates.race_nav(getData().races);
}

function listRaces(tome, r) {
    return Handlebars.templates.race(getData().races.races_by_id[r]);
}

/**loadDataIfNeeded for races */
function loadRacesIfNeeded(success) {
    loadDataIfNeeded('races', function(data) {
        fixupRaces(tome);
        success(data);
    });
}

function handleUnknownRace(tome, r) {
    document.title += ' - ' + toTitleCase(r);

    $("#content-container").scrollTop(0);

    $("#content").html('<div class="alert alert-warning">The ' + escapeHtml(r) + ' race does not exist in ToME ' + versions.name(versions.current) + '.</div>');
}
