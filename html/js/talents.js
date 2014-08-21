// See http://stackoverflow.com/a/92819/25507
function talentImgError(image) {
    image.onerror = "";
    image.src = "img/000000-0.png";
    return true;
}

var talent_img = Handlebars.registerPartial("talent_img",
    '<img width="{{opt "imgSize"}}" height="{{opt "imgSize"}}" src="img/talents/{{opt "imgSize"}}/{{#if image}}{{image}}{{else}}{{toLowerCase short_name}}.png{{/if}}" onerror="talentImgError(this)">'
);

var talent_details = Handlebars.registerPartial("talent",
    "<dl class='dl-table'>" +
        "{{#if require}}<dt>Requirements</dt><dd>{{require}}</dd>{{/if}}" +
        "{{#if mode}}<dt>Use Mode</dt><dd>{{mode}}</dd>{{/if}}" +
        "{{#if cost}}<dt>Cost</dt><dd>{{{cost}}}</dd>{{/if}}" +
        "{{#if range}}<dt>Range</dt><dd>{{{range}}}</dd>{{/if}}" +
        "{{#if cooldown}}<dt>Cooldown</dt><dd>{{{cooldown}}}</dd>{{/if}}" +
        "{{#if use_speed}}<dt>Use Speed</dt><dd>{{use_speed}}</dd>{{/if}}" +
        '{{#if info_text}}<dt class="multiline-dd">Description</dt><dd>{{{info_text}}}</dd>{{/if}}' +
    '</dl>'
);

var talent_by_type_template = Handlebars.compile(
    // FIXME: type header and description
    "{{#each this}}" +
        '<h2><a class="anchor" id="talents/{{type}}"></a>{{toTitleCase name}}</h2><div>' +
        '<p>{{description}}</p><div>' +
        "{{#each talents}}" +
            '<div class="panel panel-default">' +
                '<div class="panel-heading clickable">' +
                    '<h3 class="panel-title">' +
                        '<a data-toggle="collapse" data-target="#collapse-{{toHtmlId id}}">' +
                            '{{> talent_img}}{{name}}' +
                        '</a>' +
                    '</h3>' +
                '</div>' +
                '<div id="collapse-{{toHtmlId id}}" class="talent-details panel-collapse collapse">' +
                    '<div class="panel-body">' +
                        '{{> talent}}' +
                        '{{#if source_code}}<div class="source-link"><a href="http://git.net-core.org/darkgod/t-engine4/blob/{{tag}}/game/modules/tome/{{source_code.[0]}}#L{{source_code.[1]}}" target="_blank">View source</a></div>{{/if}}' +
                    '</div>' +
                '</div>' +
            '</div>' +
        "{{/each}}</div></div>" +
    "{{/each}}"
);

var talent_by_type_nav_template = Handlebars.compile(
    '<ul id="nav-talents" class="nav">' +
    '{{#if hasMinorChanges}}' +
        '<li><a href="#recent-changes/talents{{currentQuery}}"><span class="no-dropdown"></span>New in {{version}}</a></li>' +
    '{{/if}}' +
    '{{#if hasMajorChanges}}' +
        '<li><a href="#changes/talents{{currentQuery}}"><span class="no-dropdown"></span>New in {{majorVersion}}</a></li>' +
    '{{/if}}' +
    '{{#each talent_categories}}' +
        '<li><a href="#talents/{{toHtmlId this}}{{currentQuery}}"><span data-toggle="collapse" data-target="#nav-{{toHtmlId this}}" class="dropdown collapsed"></span>{{toTitleCase this}}</a>' +
        '<ul class="nav collapse" id="nav-{{toHtmlId this}}">' +
        // Empty for now; will be populated later
        "</ul></li>" +
    "{{/each}}</ul>"
);

var changes_talents_template = Handlebars.compile(
    "{{#each this}}" +
        '<h3><a class="anchor" id="changes/talents/{{name}}"></a>{{toTitleCase name}}</h3><div>' +
        "{{#each values}}" +
            '<div class="panel panel-default">' +
                '<div class="panel-heading clickable">' +
                    '<h3 class="panel-title">' +
                        '<a data-toggle="collapse" data-target="#collapse-{{type}}-{{toHtmlId value.id}}">' +
                            '{{> talent_img value}}{{{labelForChangeType type}}} {{value.name}}' +
                        '</a>' +
                    '</h3>' +
                '</div>' +
                '<div id="collapse-{{type}}-{{toHtmlId value.id}}" class="talent-details panel-collapse collapse">' +
                        '{{#if value2}}' +
                            '<table class="table table-bordered old-new">' +
                                '<colgroup>' +
                                    '<col width="50%">' +
                                    '<col width="50%">' +
                                '</colgroup>' +
                                '<tr><th>Old</th><th>New</th></tr><tr>' +
                                    '<td>{{> talent value2}}</td>' +
                                    '<td>{{> talent value}}</td>' +
                                '</tr>' +
                            '</table>' +
                        '{{else}}' + 
                            '<div class="panel-body">' +
                                '{{> talent value}}' +
                            '</div>' +
                        '{{/if}}' +
                '</div>' +
            '</div>' +
        "{{/each}}</div></div>" +
    "{{else}}" +
        "<p>No talent changes in this version.</p>" +
    "{{/each}}"
);

function navTalents(tome) {
    return talent_by_type_nav_template(tome[versions.current]);
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
    return talent_by_type_template(tome[versions.current].talents[category]);
}

function listChangesTalents(tome) {
    return changes_talents_template(tome[versions.current].changes.talents);
}

function listRecentChangesTalents(tome) {
    return changes_talents_template(tome[versions.current]["recent-changes"].talents);
}

