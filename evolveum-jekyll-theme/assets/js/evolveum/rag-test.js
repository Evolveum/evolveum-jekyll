(function() {
    // function sendLike(modify) {
    //     let url = window.location.href
    //     let id = url.replace("https://{{ site.environment.docsUrl }}", "").replace(/\//g, "") + "title"

    //     let queryDocsLikes = {
    //         script: {
    //             source: "if (ctx._source['docslikes'] != null) { ctx._source['docslikes'] " + modify + "= 1 } else { ctx._source['docslikes'] =" + modify + "1 }"
    //         }
    //     }

    //     $.ajax({
    //         method: "POST",
    //         url: "https://{{ site.environment.searchUrl }}/docs/_update/" + id + "?refresh",
    //         crossDomain: true,
    //         async: true,
    //         data: JSON.stringify(queryDocsLikes),
    //         dataType: 'json',
    //         contentType: 'application/json',
    //     }).fail(function(data) {
    //         console.log(data);
    //     });
    //     //OSrequest("POST", "https://searchtest.evolveum.com/docs/_update/" + id + "?refresh", queryUpvote, true)
    // }

    // $("#yesSiteReviewThumb").on("click", function() {
    //     $(this).toggleClass('on');
    //     if ($("#noSiteReviewThumb")[0].classList.contains("on")) {
    //         $("#noSiteReviewThumb").toggleClass('on');
    //     } else {
    //         $(".thanksFeedback").toggleClass('on');
    //     }
    //     if ($(this)[0].classList.contains("on")) {
    //         sendLike("+");
    //     } else {
    //         sendLike("-")
    //     }

    // });

    // $("#noSiteReviewThumb").on("click", function() {
    //     $(this).toggleClass('on');
    //     if ($("#yesSiteReviewThumb")[0].classList.contains("on")) {
    //         $("#yesSiteReviewThumb").toggleClass('on');
    //         sendLike("-");
    //     } else {
    //         $(".thanksFeedback").toggleClass('on');
    //     }
    //     if ($(this)[0].classList.contains("on")) {
    //         sendLike("-");
    //     } else {
    //         sendLike("+")
    //     }
    // });

    $('#ragPopover').popover({
        html: true,
        sanitize: false,
        placement: "left",
        container: '#search-modal',
        title: "Please tell us more about what you don't like",
        template: '<div class="popover" style="width: 50rem; max-width: 50rem;" role="tooltip"><div class="arrow"></div><h3 class="popover-header"></h3><div class="popover-body"></div></div>',
        content: `<div id="ragChatBody">
                    <div class="form-group">
                        <label for="llmResponseArea">Response</label>
                        <textarea class="form-control" id="llmResponseArea" rows="12" readonly></textarea>
                    </div>
                    <div class="form-group">
                        <label for="userQueryArea">Query</label>
                        <textarea class="form-control" id="userQueryArea" rows="2"></textarea>
                    </div>
                    <span id="ragChatPopoverButtons">
                        <button type="button" class="btn btn-primary" id="ragChatCloseButton">Close</button>
                        <button type="button" class="btn btn-primary" id="ragChatSendButton">Send message</button>
                    </span>
                </div>`
    })

    $('#ragChatCloseButton').click(function() {
        $('#ragPopover').popover('hide');
    });

    // $('#noSiteReviewThumb').on('inserted.bs.popover', function() {
    //     $('#reportDocsProblemPopoverClose').click(function() {
    //         $('#noSiteReviewThumb').popover('hide');
    //     });

    //     $('#docsReportAProblemSelect').selectpicker();

    //     $('#docsReportTextArea').on('focus', function() {
    //         $(document).off('keydown');
    //     });

    //     $('#reportDocsProblemPopoverSend').click(function() {
    //         let docsProblemSelected = $(".docsReportAProblemOption.selected")
    //         let docsProblemCategory = "Not defined"
    //         if (docsProblemSelected[0] != undefined) {
    //             docsProblemCategory = docsProblemSelected[0].childNodes[0].textContent
    //         }

    //         let reportdocsQuery = {
    //             category: docsProblemCategory,
    //             details: $("#docsReportTextArea").val(),
    //             width: $(document).width(),
    //             height: $(document).height()
    //         }
    //         $.ajax({
    //             method: "POST",
    //             url: "https://{{ site.environment.docsUrl }}/webhooks/report/docs",
    //             crossDomain: true,
    //             async: true,
    //             data: JSON.stringify(reportdocsQuery),
    //             dataType: 'json',
    //             contentType: 'application/json',
    //         }).fail(function(data) {
    //             console.log(data);
    //         });
    //         $('#noSiteReviewThumb').popover('hide');
    //     });
    // })
})();