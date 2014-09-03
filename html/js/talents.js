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
