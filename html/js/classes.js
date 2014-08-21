var class_nav_template = Handlebars.compile(
    '<ul id="nav-classes" class="nav">' +
    /*'{{#if hasMinorChanges}}' +
        '<li><a href="#recent-changes/talents{{currentQuery}}"><span class="no-dropdown"></span>New in {{version}}</a></li>' +
    '{{/if}}' +
    '{{#if hasMajorChanges}}' +
        '<li><a href="#changes/talents{{currentQuery}}"><span class="no-dropdown"></span>New in {{majorVersion}}</a></li>' +
    '{{/if}}' +*/
    '{{#each class}}' +
        '<li><a href="#classes/{{toHtmlId short_name}}{{currentQuery}}"><span data-toggle="collapse" data-target="#nav-{{toHtmlId short_name}}" class="dropdown collapsed"></span>{{toTitleCase display_name}}</a>' +
        '<ul class="nav collapse" id="nav-{{toHtmlId short_name}}">' +
            '{{#each subclass}}' +
                '<li><a href="#classes/{{toHtmlId ../short_name}}/{{toHtmlId short_name}}{{currentQuery}}">{{toTitleCase display_name}}</a></li>' +
            '{{/each}}' +
        "</ul></li>" +
    "{{/each}}</ul>"
);

function navClasses(tome) {
    return class_nav_template(tome[versions.current].classes);
}


