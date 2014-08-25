function fixupClasses(tome) {
    var c = tome[versions.current].classes;

    if (tome[versions.current].fixups.classes) {
        return;
    }

    // Replace IDs in class_list with references to the actual class definition.
    c.class_list = _.map(c.class_list, function(cls) { return c.classes[cls]; });

    // Replace subclass IDs in each class's subclass_list with references
    // to the actual subclass definition.
    _.each(c.classes, function(elem) {
        elem.subclass_list = _.map(elem.subclass_list, function(sub) { return c.subclasses[sub]; });
        elem.single_subclass = elem.subclass_list.length == 1
    });

    c.classes_by_id = indexByHtmlId(c.classes, 'short_name');

    tome[versions.current].fixups.classes = true;
}

function navClasses(tome) {
    fixupClasses(tome);
    return Handlebars.templates.class_nav(tome[versions.current].classes);
}

function listClasses(tome, cls) {
    fixupClasses(tome);
    return Handlebars.templates.class(tome[versions.current].classes.classes_by_id[cls]);
}
