function fixupRaces(tome) {
    var r = tome[versions.current].races;

    if (tome[versions.current].fixups.races) {
        return;
    }

    // Replace IDs in race_list with references to the actual race definition.
    r.race_list = _.map(r.race_list, function(race) { return r.races[race]; });

    // Store a reference from each subrace back to the race ID.
    _.each(r.races, function(elem) {
        _.each(elem.subrace_list, function (sub) {
            var exp_penalty = r.subraces[sub].experience;
            exp_penalty = (exp_penalty || 1.0) - 1.0;
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

    tome[versions.current].fixups.races = true;
}

function navRaces(tome) {
    return Handlebars.templates.race_nav(tome[versions.current].races);
}

function listRaces(tome, r) {
    return Handlebars.templates.race(tome[versions.current].races.races_by_id[r]);
}

/**loadDataIfNeeded for races */
function loadRacesIfNeeded(success) {
    loadDataIfNeeded('races', function(data) {
        fixupRaces(tome);
        success(data);
    });
}
