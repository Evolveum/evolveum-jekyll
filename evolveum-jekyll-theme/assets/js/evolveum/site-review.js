$("#yesSiteReviewThumb").on("click", function() {
    $(this).toggleClass('on');
    if ($("#noSiteReviewThumb").classList.contains(on)) {
        $("#noSiteReviewThumb").toggleClass('on');
    } else {
        $(".thanksFeedback").toggleClass('on');
    }
});

$("#noSiteReviewThumb").on("click", function() {
    $(this).toggleClass('on');
    $(".thanksFeedback").toggleClass('on');
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
            url: "https://docstest.evolveum.com/webhooks/report/docs",
            crossDomain: true,
            async: true,
            data: JSON.stringify(reportdocsQuery),
            dataType: 'json',
            contentType: 'application/json',
        }).fail(function(data) {
            console.log(data);
        });
        $('#reportdocsProblemPopover').popover('hide');
    });
})