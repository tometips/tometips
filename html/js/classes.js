function fixupClasses(tome) {
  var data = getData();
    var c = data.classes;

    if (data.fixups.classes) {
        return;
    }

    // Replace IDs in class_list with references to the actual class definition.
    c.class_list = _.map(c.class_list, function(cls) { return c.classes[cls]; });

    // Store a reference from each subclass back to the class ID.
    _.each(c.classes, function(elem) {
        _.each(elem.subclass_list, function (sub) {
            c.subclasses[sub].class_short_name = elem.short_name;
        });
    });

    // Replace subclass IDs in each class's subclass_list with references
    // to the actual subclass definition.
    _.each(c.classes, function(elem) {
        elem.subclass_list = _.map(elem.subclass_list, function(sub) { return c.subclasses[sub]; });
        elem.single_subclass = elem.subclass_list.length == 1;
    });

    c.classes_by_id = indexByHtmlId(c.classes, 'short_name');

    data.fixups.classes = true;
}

function navClasses(tome) {
    return Handlebars.templates.class_nav(getData().classes);
}

function listClasses(tome, cls) {
    return Handlebars.templates.class(getData().classes.classes_by_id[cls]);
}

function fillClassTalents(tome, cls) {
    var data = getData();
    var subclasses = data.classes.classes_by_id[cls].subclass_list,
        load_talents = {};

    function list_class_talents(value, key, list) {
        var category = key.split(/ ?\/ ?/)[0];
        load_talents[category] = load_talents[category] || {};
        load_talents[category][key] = true;
    }

    for (var i = 0; i < subclasses.length; i++) {
        _.each(subclasses[i].talents_types_class, list_class_talents);
        _.each(subclasses[i].talents_types_generic, list_class_talents);
    }

    _.each(load_talents, function(talents, category, list) {
        loadDataIfNeeded('talents.' + category, function() {
            _.each(talents, function(value, this_type, list) {
                // TODO: Should index talents by talent_type as well as sequential list to avoid the need to use _.find
                var talent_details = _.find(getData().talents[category], function(t) { return t.type == this_type; }),
                    talent_html = Handlebars.partials.class_talents_detail(talent_details);
                $('.class-talents-detail[data-talent-type="' + toHtmlId(this_type) + '"]').html(talent_html);
            });

            markupHintLinks();
        });
    });
}

/**loadDataIfNeeded for classes */
function loadClassesIfNeeded(success) {
    loadDataIfNeeded('classes', function(data) {
        fixupClasses(tome);
        success(data);
    });
}
