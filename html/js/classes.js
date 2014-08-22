var class_nav_template = Handlebars.compile(
    '<ul id="nav-classes" class="nav">' +
    /*'{{#if hasMinorChanges}}' +
        '<li><a href="#recent-changes/talents{{currentQuery}}"><span class="no-dropdown"></span>New in {{version}}</a></li>' +
    '{{/if}}' +
    '{{#if hasMajorChanges}}' +
        '<li><a href="#changes/talents{{currentQuery}}"><span class="no-dropdown"></span>New in {{majorVersion}}</a></li>' +
    '{{/if}}' +*/
    '{{#each class_list}}' +
        '<li><a href="#classes/{{toHtmlId short_name}}{{currentQuery}}"><span data-toggle="collapse" data-target="#nav-{{toHtmlId short_name}}" class="dropdown collapsed"></span>{{toTitleCase display_name}}</a>' +
        '<ul class="nav collapse" id="nav-{{toHtmlId short_name}}">' +
            '{{#each subclass_list}}' +
                '<li><a href="#classes/{{toHtmlId ../short_name}}/{{toHtmlId short_name}}{{currentQuery}}">{{toTitleCase display_name}}</a></li>' +
            '{{/each}}' +
        "</ul></li>" +
    "{{/each}}</ul>"
);

var class_template = Handlebars.compile(
    '<h2><a class="anchor" id="classes/{{toHtmlId short_name}}"></a>{{toTitleCase display_name}}</h2><div>' +
        '{{#if locked_desc}}<p class="flavor">{{locked_desc}}</p>{{/if}}' +
        '{{{desc}}}' +
        '{{#each subclass_list}}' +
            '<h3><a class="anchor" id="classes/{{toHtmlId ../short_name}}/{{toHtmlId short_name}}"></a>{{toTitleCase display_name}}</h3>' +
            '{{#if locked_desc}}<p class="flavor">{{locked_desc}}</p>{{/if}}' +
            '{{{desc}}}' +
        '{{/each}}' +
    '</div>'
);

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
    });

    c.classes_by_id = indexByHtmlId(c.classes, 'short_name');

    tome[versions.current].fixups.classes = true;
}

function navClasses(tome) {
    fixupClasses(tome);
    return class_nav_template(tome[versions.current].classes);
}

function listClasses(tome, cls) {
    fixupClasses(tome);
    return class_template(tome[versions.current].classes.classes_by_id[cls]);
}

