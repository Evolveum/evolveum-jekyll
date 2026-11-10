$(document).ready(function() {

    const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)");

    const $fixedPanel = $("#navtree-panel.navtree-fixed");
    const current = $fixedPanel.find('[aria-current="page"]')[0];
    if (current && $fixedPanel.is(":visible")) {
        const panel = $fixedPanel[0];
        const top = current.getBoundingClientRect().top - panel.getBoundingClientRect().top;
        if (top + current.offsetHeight > panel.clientHeight) {
            panel.scrollTop += top - panel.clientHeight / 3;
        }
    }

    $("#navtree-toggle").click(function() {
        const $toggle = $(this);
        const $navtree = $("#" + $toggle.attr("aria-controls"));
        const opening = $navtree.hasClass("d-none");
        const duration = reduceMotion.matches ? 0 : 400;

        if (opening) {
            $navtree.removeClass("d-none").css({
                'height': '0',
                'overflow': 'hidden'
            }).animate({
                'height': $navtree[0].scrollHeight + 'px'
            }, duration, function() {
                $navtree.css({
                    'height': '',
                    'overflow': ''
                });
            });
        } else {
            const originalHeight = $navtree.height();
            $navtree.css({
                'height': originalHeight + 'px',
                'overflow': 'hidden'
            }).animate({
                'height': '0'
            }, duration, function() {
                $navtree.addClass("d-none").css({
                    'height': '',
                    'overflow': ''
                });
            });
        }

        $toggle.attr("aria-expanded", opening ? "true" : "false");
        $toggle.find("i")
            .toggleClass("fa-angle-down", !opening)
            .toggleClass("fa-angle-up", opening);
    });

});
