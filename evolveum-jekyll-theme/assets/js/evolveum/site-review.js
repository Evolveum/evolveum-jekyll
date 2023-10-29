$(".siteReviewThumb").on("click", function() {
    $(this).toggleClass('on');
    $(".thanksFeedback").toggleClass('on');
});

$('#noSiteReviewThumb').popover({
    html: true,
    sanitize: false,
    container: '#pageEval',
    title: "Report a problem",
    content: `<div>
                <div class="form-group">
                    <label for="docsReportAProblemSelect">Please tell us more about what you don't like</label>
                    <select id="docsReportAProblemSelect" data-style="btn-light btn-sm btnSearchSelectReport" title="Type of a problem" data-width="auto">
                        <option class="input-sm searchReportAProblemOption">Visual bug</option>
                        <option class="input-sm searchReportAProblemOption">Functional bug</option>
                        <option class="input-sm searchReportAProblemOption">Problem with results</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="searchReportTextArea">Details of the problem</label>
                    <textarea class="form-control" id="searchReportTextArea" rows="5"></textarea>
                </div>
                <span>
                    <button type="button" class="btn btn-primary" id="reportDocsProblemPopoverClose">Close</button>
                    <button type="button" class="btn btn-primary" id="reportDocsProblemPopoverSend">Send message</button>
                </span>
            </div>`
});

$('#noSiteReviewThumb').on('inserted.bs.popover', function() {
    $('#reportDocsProblemPopoverClose').click(function() {
        $('#reportDocsProblemPopover').popover('hide');
    });

    $('#docsReportAProblemSelect').selectpicker();

    // $('#reportSearchProblemPopoverSend').click(function() {
    //     let searchProblemSelected = $(".searchReportAProblemOption.selected")
    //     let searchProblemCategory = "Not defined"
    //     if (searchProblemSelected[0] != undefined) {
    //         searchProblemCategory = searchProblemSelected[0].childNodes[0].textContent
    //     }

    //     let reportSearchQuery = {
    //         category: searchProblemCategory,
    //         details: $("#searchReportTextArea").val(),
    //         query: document.getElementById('searchbar').value,
    //         width: $(document).width(),
    //         height: $(document).height()
    //     }
    //     OSrequest("POST", "https://docstest.evolveum.com/webhooks/docsreport", reportSearchQuery, true)
    //     $('#reportSearchProblemPopover').popover('hide');
    // });
})