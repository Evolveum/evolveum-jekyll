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
        title: "Chat with an ai. Please be cautious, this ai is prone to hallucinate",
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

    $('#ragPopover').on('inserted.bs.popover', function() {
        $('#ragChatCloseButton').click(function() {
            $('#ragPopover').popover('hide');
        });
        $('#ragChatSendButton').click(function() {
            sendRagRequest()
        });
    });

    async function sendRagRequest() {
        const postData = {
                "_source": {
                    "excludes": [
                        "passage_embedding"
                    ]
                },
                "indices_boost": [
                    { "pass1-nlp-index": 1.0 },
                    { "bookpass-nlp-index": 1.5 }
                ],
                "query": {
                    "bool": {
                        "filter": {
                            "terms": { "branch.keyword": ["support-4.8", "notBranched"] }
                        },
                        "should": [{
                                "script_score": {
                                    "query": {
                                        "neural": {
                                            "passage_embedding": {
                                                "query_text": "Object template examples",
                                                "model_id": "ueVVfo4Bvd-X9jaivNwl",
                                                "k": 100
                                            }
                                        }
                                    },
                                    "script": {
                                        "source": "_score * 1.5"
                                    }
                                }
                            },
                            {
                                "script_score": {
                                    "query": {
                                        "match": {
                                            "text": "Object template examples"
                                        }
                                    },
                                    "script": {
                                        "source": "_score * 0.8"
                                    }
                                }
                            }
                        ]
                    }
                }
            }
            // const customHeaders = {
            //     'Content-Type': 'application/json'
            // };
            // // Define your Axios configuration
            // const axiosConfig = {
            //     // Your Axios configuration here
            //     headers: customHeaders,
            //     responseType: 'stream' // Set the responseType to 'stream' to receive a stream response
            // };

        // let context = []

        const rawResponse = await fetch('https://rag-test.lab.evolveum.com', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(postData)
        });

        // Iterate response.body (a ReadableStream) asynchronously
        for await (const chunk of rawResponse.body) {
            // Do something with each chunk
            // Here we just accumulate the size of the response.
            console.log(chunk)
        }
    }

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