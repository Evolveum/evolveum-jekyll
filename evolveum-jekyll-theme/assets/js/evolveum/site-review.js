---
---
(function() {
    function sendLike(modify) {
        let url = window.location.href
        let id = url.replace("https://docs.evolveum.com", "").replace(/\//g, "") + "title"

        let queryDocsLikes = {
            script: {
                source: "if (ctx._source['docslikes'] != null) { ctx._source['docslikes'] " + modify + "= 1 } else { ctx._source['docslikes'] =" + modify  + "1 }"
            }
        }
    
        $.ajax({
            method: "POST",
            url: "https://search.evolveum.com/docs/_update/" + id + "?refresh",
            crossDomain: true,
            async: true,
            data: JSON.stringify(queryDocsLikes),
            dataType: 'json',
            contentType: 'application/json',
        }).fail(function(data) {
            console.log(data);
        });
        //OSrequest("POST", "https://searchtest.evolveum.com/docs/_update/" + id + "?refresh", queryUpvote, true)
    }
    
    $("#yesSiteReviewThumb").on("click", function() {
        $(this).toggleClass('on');
        if ($("#noSiteReviewThumb")[0].classList.contains("on")) {
            $("#noSiteReviewThumb").toggleClass('on');
        } else {
            $(".thanksFeedback").toggleClass('on');
        }
        if ($(this)[0].classList.contains("on")) {
            sendLike("+");
        } else {
            sendLike("-")
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
            sendLike("-");
        } else {
            sendLike("+")
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
    
        $('#docsReportTextArea').on('focus', function() {
            $(document).off('keydown');
        });
    
        $('#reportDocsProblemPopoverSend').click(function() {
            let docsProblemSelected = $(".docsReportAProblemOption.selected")
            let docsProblemCategory = "Not defined"
            if (docsProblemSelected[0] != undefined) {
                docsProblemCategory = docsProblemSelected[0].childNodes[0].textContent
            }
    
            let reportdocsQuery = {
                category: docsProblemCategory,
                details: $("#docsReportTextArea").val(),
                width: $(document).width(),
                height: $(document).height()
            }
            $.ajax({
                method: "POST",
                url: "https://docs.evolveum.com/webhooks/report/docs",
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