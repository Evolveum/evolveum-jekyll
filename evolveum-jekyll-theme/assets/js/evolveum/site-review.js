---
---
(function() {
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
        
    });
    
    $("#noSiteReviewThumb").on("click", function() {
        $(this).toggleClass('on');
        if ($("#yesSiteReviewThumb")[0].classList.contains("on")) {
            $("#yesSiteReviewThumb").toggleClass('on');
            sendLike("-");
        } else {
            $(".thanksFeedback").toggleClass('on');
        }
        if ($(this)[0].classList.contains("on")) {
            sendLike(false);
        } else {
            sendLike(true);
        }
    });
    
    $('#noSiteReviewThumb').popover({
        html: true,
        sanitize: false,
        container: '#pageEval',
        title: "Please tell us more about what you don't like",
        content: `<div>
                    <div class="form-group">
                        <label for="docsReportAProblemSelect">Type of a problem</label>
                        <select id="docsReportAProblemSelect" data-style="btn-light btn-sm btndocsSelectReport" title="Type of a problem" data-width="auto">
                            <option class="input-sm docsReportAProblemOption">Visual bug</option>
                            <option class="input-sm docsReportAProblemOption">Functional bug</option>
                            <option class="input-sm docsReportAProblemOption">Problem with content</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label for="docsReportTextArea">Details of the problem</label>
                        <textarea class="form-control" id="docsReportTextArea" rows="5"></textarea>
                    </div>
                    <span>
                        <button type="button" class="btn btn-primary" id="reportDocsProblemPopoverClose">Close</button>
                        <button type="button" class="btn btn-primary" id="reportDocsProblemPopoverSend">Send message</button>
                    </span>
                </div>`
    });
    
    $('#noSiteReviewThumb').on('inserted.bs.popover', function() {
        $('#reportDocsProblemPopoverClose').click(function() {
            $('#noSiteReviewThumb').popover('hide');
        });
    
        $('#docsReportAProblemSelect').selectpicker();
    
        $('#reportDocsProblemPopoverSend').click(function() {
            let docsProblemSelected = $(".docsReportAProblemOption.selected")
            let docsProblemCategory = "Not defined"
            if (docsProblemSelected[0] != undefined) {
                docsProblemCategory = docsProblemSelected[0].childNodes[1].textContent
            }

            let details = $("#docsReportTextArea").val()
            if (details == undefined || details == "") {
                details = "No details provided"
            }
    
            let reportdocsQuery = {
                category: docsProblemCategory,
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
            $('#noSiteReviewThumb').popover('hide');
        });
    })
})();
