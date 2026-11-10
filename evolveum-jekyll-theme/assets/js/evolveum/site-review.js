---
---
(function() {
    function syncFeedback() {
        const yesOn = $("#yesSiteReviewThumb").hasClass("on");
        const noOn = $("#noSiteReviewThumb").hasClass("on");
        $("button#yesSiteReviewThumb").attr("aria-pressed", yesOn ? "true" : "false");
        $("button#noSiteReviewThumb").attr("aria-pressed", noOn ? "true" : "false");
        $(".thanksFeedback").text(yesOn || noOn ? "Thanks for your feedback" : "");
    }

    function sendLike(modify) {
        let url = window.location.href
        let id = url.replace("https://{{ site.environment.docsUrl }}", "").replace(/\//g, "") + "title"

        let queryDocsLikes = {
            "id": id,
            "like": modify
        }
    
        $.ajax({
            {% if site.environment.name contains "guide" %}
            headers: { 'X-API-Key': {{ site.environment.guideKey | jsonify }} },
            {% endif %}
            method: "POST",
            url: "https://{{ site.environment.searchUrl }}/api/v1/likes/{% if site.environment.name contains "docs" %}docs{% else %}guide{% endif %}",
            crossDomain: true,
            async: true,
            data: JSON.stringify(queryDocsLikes),
            dataType: 'json',
            contentType: 'application/json',
        }).fail(function(data) {
            console.log(data);
        });
        //OSrequest("POST", "https://search.evolveum.com/docs/_update/" + id + "?refresh", queryUpvote, true)
    }
    
    $("#yesSiteReviewThumb").on("click", function() {
        $(this).toggleClass('on');
        if ($("#noSiteReviewThumb")[0].classList.contains("on")) {
            $("#noSiteReviewThumb").toggleClass('on');
        } else {
            $(".thanksFeedback").toggleClass('on');
        }
        if ($(this)[0].classList.contains("on")) {
            sendLike(true);
        } else {
            sendLike(false)
        }
        syncFeedback();

    });
    
    const report = document.getElementById("docs-report");

    $(document).on("click", "[data-ev-report]", function() {
        if (report) {
            report.showModal();
        }
    });

    $("#noSiteReviewThumb").on("click", function() {
        $(this).toggleClass('on');
        if ($("#yesSiteReviewThumb").hasClass("on")) {
            $("#yesSiteReviewThumb").toggleClass('on');
            sendLike(false);
        } else {
            $(".thanksFeedback").toggleClass('on');
        }
        if ($(this).hasClass("on")) {
            sendLike(false);
        } else {
            sendLike(true);
        }
        if ($(this).hasClass("on") || !$("button#yesSiteReviewThumb").length) {
            report.showModal();
        }
        syncFeedback();
    });

    $("#docs-report").on("close", function() {
        this.querySelector("form").reset();
    });

    $("#docs-report-send").on("click", function() {
        let details = $("#docs-report-details").val()
        if (details == undefined || details == "") {
            details = "No details provided"
        }

        let reportdocsQuery = {
            category: $("#docs-report-type").val() || "Not defined",
            details: details,
            width: $(document).width(),
            height: $(document).height()
        }
        $.ajax({
            method: "POST",
            url: "https://{{ site.environment.docsUrl }}/webhooks/report/docs",
            crossDomain: true,
            async: true,
            data: JSON.stringify(reportdocsQuery),
            dataType: 'json',
            contentType: 'application/json',
        }).fail(function(data) {
            console.log(data);
        });
        report.close();
    });
})();
