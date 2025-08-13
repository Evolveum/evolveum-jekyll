$(document).ready(function() {

    $("#navtree-toggle").click(function() {
        const $navtree = $(".navtree-column");

        if ($navtree.hasClass("d-none")) {
            $navtree.removeClass("d-none").css({
                'height': '0',
                'overflow': 'hidden'
            }).animate({
                'height': $navtree[0].scrollHeight + 'px'
            }, 400, function() {
                $navtree.css('height', '');
            });
        } else {
            const originalHeight = $navtree.height();
            $navtree.css({
                'height': originalHeight + 'px',
                'overflow': 'hidden'
            }).animate({
                'height': '0'
            }, 400, function() {
                $navtree.addClass("d-none").css({
                    'height': '',
                    'overflow': ''
                });
            });
        }

        if ($("#navtree-toggle i").hasClass("fa-angle-down")) {
            $("#navtree-toggle i").removeClass("fa-angle-down").addClass("fa-angle-up");
        } else {
            $("#navtree-toggle i").removeClass("fa-angle-up").addClass("fa-angle-down");
        }
    });

});