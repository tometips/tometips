// See http://stackoverflow.com/a/92819/25507
function talentImgError(image) {
    image.onerror = "";
    image.src = "img/000000-0.png";
    return true;
}

function navTalents(tome) {
    return Handlebars.templates.talent_by_type_nav(tome[versions.current]);
}

function loadNavTalents($el) {
   var category = $el.attr('id').replace('nav-', '');
   loadDataIfNeeded('talents.' + category, function() {
        fillNavTalents(tome, category);
   });
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
    return Handlebars.templates.talent_by_type(tome[versions.current].talents[category]);
}

function listChangesTalents(tome) {
    return Handlebars.templates.changes_talents(tome[versions.current].changes.talents);
}

function listRecentChangesTalents(tome) {
    return Handlebars.templates.changes_talents(tome[versions.current]["recent-changes"].talents);
}

/**Adds "Availability:" paragraphs to already rendered talent listings,
 * showing which classes can learn each talent. */
function fillTalentAvailability(tome, category) {
    var show;

    // The set of talent types we're interested in showing
    show = _.object(_.map(tome[versions.current].talents[category], function(t) {
        return [t.type, []];
    }));

    loadClassesIfNeeded(function() {
        var subclasses = tome[versions.current].classes.subclasses,
            sorted_subclasses = _.sortBy(subclasses, 'name');
        _.each(sorted_subclasses, function(sub) {
            _.each([ sub.talents_types_class, sub.talents_types_generic ], function(sub_talents_types) {
                _.each(sub_talents_types, function(value, key) {
                    var desc;
                    if (show[key]) {
                        if (sub.class_short_name) {
                            // No associated class = inaccessible subclass
                            // (like Tutorial Adventurer)
                            show[key].push(Handlebars.partials.talent_classes({ subclass: sub, value: value }));
                        }
                    }
                });
            });
        });

        _.each(show, function(value, key) {
            if (value.length) {
                $("#talents\\/" + key.replace('/', '\\/') + "-avail").html('Availability: ' + value.join(', '));
            }
        });

        markupHintLinks();

        // HACK: Because we've changed page length, we probably just
        // invalidated scrollToId, so redo that. Is a better approach possible?
        scrollToId();
    });
}
