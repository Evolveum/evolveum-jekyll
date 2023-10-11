(function() {

    let letters = new Set(["Guide", "Reference", "Developer", "Other"]);
    let branches = new Set(["notBranched"])
    let notMasterBranchMult = 0
    let branchColors = new Map();

    window.addEventListener('load', function() {
        let start = 40
        let end = 215
        let step = (end - start) / ALLDOCSBRANCHES.size
        for (br in ALLDOCSBRANCHES) {
            branchColors.set(ALLDOCSBRANCHES[br], start + (br*step))
        }
    })

    $('#select-version-picker-search').on('changed.bs.select', function(e, clickedIndex, isSelected, previousValue) {
        let newVersion = $(this).find('option').eq(clickedIndex).text();
        let newVersionEdited = newVersion.charAt(0).toLowerCase() + newVersion.slice(1)
        console.log(newVersionEdited)
        let queryArr = searchQuery.query.bool.must[0].function_score.script_score.script.source.split("\n")
        let queryLen = queryArr.length
        console.log(clickedIndex + " " + isSelected)
        if (isSelected) {
            branches.add(newVersionEdited)
            if (queryArr[queryLen - 6].includes("branch")) {
                console.log(queryArr)
                console.log(queryArr[ queryLen - 6])
                console.log(queryLen)
                searchQuery.query.bool.must[0].function_score.script_score.script.source = queryArr.slice(0,queryLen - 7).join("\n") +  "\n" + queryArr[queryLen-2]
                searchQuery.query.bool.filter.push({ terms: { "branch.keyword": Array.from(branches) }})
            } else {
                searchQuery.query.bool.filter[1].terms["branch.keyword"] = Array.from(branches)
            }
        } else {
            branches.delete(newVersionEdited)
            console.log(branches)
            if (branches.size == 1) {
                searchQuery.query.bool.must[0].function_score.script_score.script.source = queryArr.slice(0, queryLen - 1).join("\n") + "\n" + `if (doc.containsKey('branch.keyword') && doc['branch.keyword'].size()!=0) {
                    if (doc['branch.keyword'].value != "master" && doc['branch.keyword'].value != "notBranched") {
                        totalScore = totalScore*${notMasterBranchMult};
                    }
                }
                return totalScore;
                `
                searchQuery.query.bool.filter.pop()
            } else {
                searchQuery.query.bool.filter[1].terms["branch.keyword"] = Array.from(branches)
            }
        }
        searchForPhrase()
    });

    $('.ovalSearch').click(function() {
        $(this).toggleClass('on');
        let name = this.id.replace('oval', '')
        if (this.classList.contains('on')) {
            document.getElementById("check" + name).className = 'fas fa-check'
            this.innerHTML = this.innerHTML.replace(name.toUpperCase(), "&nbsp;" + name.toUpperCase())
            console.log(this.innerHTML)
            letters.add(name)
        } else {
            document.getElementById("check" + name).className = ''
            this.innerHTML = this.innerHTML.replace("&nbsp;" + name.toUpperCase(), name.toUpperCase())
            console.log(this.innerHTML + name.toUpperCase())
            letters.delete(name)
        }
        searchQuery.query.bool.filter[0].terms["type.keyword"] = Array.from(letters)
        searchForPhrase()
    });

    var typingTimer = null;
    let logTimer = null;
    let logScheduled = false

    $(document).on('keydown', function(e) {
        if (/^[a-zA-Z0-9-_ ]$/.test(e.key) && !e.altKey && !e.ctrlKey && !e.metaKey && e.which !== 32) {
            if (!$("#search-modal").hasClass('show')) {
                $("#search-modal").modal()
                typingTimer = setTimeout(searchForPhrase, 200)
                logTimer = setTimeout(sendSearchLog, 2000)
                logScheduled = true
            }
        }
    });

    $("#search-modal").on('shown.bs.modal', async function() {
        $('#searchbar').trigger('focus')
        searchReportPopoverSetup()
    });

    function searchReportPopoverSetup() {
        $('#reportSearchProblemPopover').popover({
            html: true,
            sanitize: false,
            container: '#search-modal',
            title: "Report a problem",
            content: `<div>
                        <div class="form-group">
                            <label for="searchReportAProblemSelect">Select the type of problem</label>
                            <select id="searchReportAProblemSelect" data-style="btn-light btn-sm btnSearchSelectReport" title="Type of a problem" data-width="auto">
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
                            <button type="button" class="btn btn-primary" id="reportSearchProblemPopoverClose">Close</button>
                            <button type="button" class="btn btn-primary" id="reportSearchProblemPopoverSend">Send message</button>
                        </span>
                    </div>`
        });

        $('#reportSearchProblemPopover').on('inserted.bs.popover', function() {
            $('#reportSearchProblemPopoverClose').click(function() {
                $('#reportSearchProblemPopover').popover('hide');
            });

            $('#searchReportAProblemSelect').selectpicker();

            $('#reportSearchProblemPopoverSend').click(function() {
                let searchProblemSelected = $(".searchReportAProblemOption.selected")
                let searchProblemCategory = "Not defined"
                if (searchProblemSelected[0] != undefined) {
                    searchProblemCategory = searchProblemSelected[0].childNodes[0].textContent
                }

                let reportSearchQuery = {
                    category: searchProblemCategory,
                    details: $("#searchReportTextArea").val(),
                    query: document.getElementById('searchbar').value,
                    width: $(document).width(),
                    height: $(document).height()
                }
                OSrequest("POST", "https://docstest.evolveum.com/webhooks/searchreport", reportSearchQuery, true)
                $('#reportSearchProblemPopover').popover('hide');
            });
        })
    }

    $("#search-modal").on('hidden.bs.modal', function() {
        document.getElementById("autocombox").innerHTML = "";
        document.getElementById("autocombox").style.display = "none";
        document.getElementById('searchToggle').value = "";
        document.getElementById('searchbar').value = "";
    });

    function OSrequest(method, url, query, async, callback) {
        if (method == "GET" && query != undefined) {
            url = url + "?source_content_type=application/json&source=" + encodeURIComponent(JSON.stringify(query).replace(/\\n\s*/g, " "))
            console.log(url)
            query = undefined
        }
        $.ajax({
            method: method,
            url: url,
            crossDomain: true,
            async: async,
            data: JSON.stringify(query),
            dataType: 'json',
            contentType: 'application/json',
        }).done(function(data) {
            if (typeof callback !== 'undefined' && callback) {
                callback(data)
            }
        }).fail(function(data) {
            console.log(data);
        });
    }

    let searchQuery = {}

    OSrequest("GET", "https://searchtest.evolveum.com/search_settings/_doc/1", undefined, true, setSearchQuery)

    function setSearchQuery(data) {
        notMasterBranchMult = data._source.multipliers.notMasterBranch
        searchQuery = {
            query: {
                bool: {
                    filter: [
                        {
                            terms: {
                                "type.keyword": Array.from(letters)
                            }
                        }
                    ],
                    must: [{
                        function_score: {
                            script_score: {
                                script: { // TODO update script
                                    source: `
                                        double totalScore = _score;
                                        if (doc.upvotes.size()!=0) {
                                            totalScore = totalScore*(1+${data._source.multipliers.upvotes}*doc.upvotes.value/100);
                                        }
                                        if (doc['_index'].value == "mpbook") {
                                            totalScore = totalScore*${data._source.multipliers.book};
                                        }
                                        if (doc.containsKey('upkeep-status.keyword') && doc['upkeep-status.keyword'].size()!=0) {
                                            if (doc['upkeep-status.keyword'].value == "yellow") {
                                                totalScore = totalScore*${data._source.multipliers.status_yellow};
                                            } else if (doc['upkeep-status.keyword'].value == "green") {
                                                totalScore = totalScore*${data._source.multipliers.status_green};
                                            } else if (doc['upkeep-status.keyword'].value == "red") {
                                                totalScore = totalScore*${data._source.multipliers.status_red};
                                            } else if (doc['upkeep-status.keyword'].value == "orange") {
                                                totalScore = totalScore*${data._source.multipliers.status_orange};
                                            }
                                        } else {
                                            totalScore = totalScore*${data._source.multipliers.status_absent};
                                        }
                                        if (doc.containsKey('lastModificationDate') && doc.lastModificationDate.size()!=0) {
                                            double timestampNow = (double)new Date().getTime();
                                            totalScore = totalScore*Math.max(${data._source.values.last_modification_min}, ${data._source.multipliers.last_modification_im}/(1+(timestampNow - doc.lastModificationDate.value.getMillis())/${data._source.values.last_modification * 24 * 60 * 60 * 1000}.0))
                                        } else {
                                            totalScore = totalScore*${data._source.multipliers.age_absent};
                                        }
                                        if (doc.containsKey('deprecated') && doc.deprecated.size()!=0) {
                                            if (doc.deprecated.value == true) {
                                                totalScore = totalScore*${data._source.multipliers.deprecated};
                                            }
                                        }
                                        if (doc.containsKey('experimental') && doc.experimental.size()!=0) {
                                            if (doc.experimental.value == true) {
                                                totalScore = totalScore*${data._source.multipliers.experimental};
                                            }
                                        }
                                        if (doc.containsKey('planned') && doc.planned.size()!=0) {
                                            if (doc.planned.value == true) {
                                                totalScore = totalScore*${data._source.multipliers.planned};
                                            }
                                        }
                                        if (doc.containsKey('outdated') && doc.outdated.size()!=0) {
                                            if (doc.outdated.value == true) {
                                                totalScore = totalScore*${data._source.multipliers.outdated};
                                            }
                                        }
                                        if (doc.containsKey('obsolete') && doc.obsolete.size()!=0) {
                                            if (doc.obsolete.value == true) {
                                                totalScore = totalScore*${data._source.multipliers.obsolete};
                                            }
                                        }
                                        if (doc.containsKey('branch.keyword') && doc['branch.keyword'].size()!=0) {
                                            if (doc['branch.keyword'].value != "master" && doc['branch.keyword'].value != "notBranched") {
                                                totalScore = totalScore*${data._source.multipliers.notMasterBranch};
                                            }
                                        }
                                        return totalScore;
                                    `
                                }
                            },
                            query: {
                                multi_match: {
                                    query: "",
                                    analyzer: "standard",
                                    fields: [
                                        "text",
                                        "title^2",
                                        "alternative_text^0.5" // TODO
                                    ],
                                    fuzziness: "AUTO",
                                    prefix_length: 2,
                                }
                            }
                        }
                    }]
                }
            },
            fields: [
                "alternative_text",
                "title",
                "lastModificationDate",
                "author",
                "upvotes",
                "upkeep-status",
                "obsolete",
                "deprecated",
                "experimental",
                "planned",
                "outdated",
                "wiki-metadata-create-user",
                "url",
                "type",
                "branch"
            ],
            _source: false,
            highlight: {
                pre_tags: [
                    "<strong>"
                ],
                post_tags: [
                    "</strong>"
                ],
                fields: {
                    title: {},
                    text: {}
                }
            }
        }
        console.log(searchQuery)
    }

    $('#searchbar').keydown(function() {
        if (event.keyCode != 38 && event.keyCode != 40) {
            if (typingTimer) {
                clearTimeout(typingTimer);
                typingTimer = null;
                console.log("timer removed")
            }
            if (logTimer) {
                clearTimeout(logTimer);
                logTimer = null;
                console.log("logtimer removed")
            }
            if ($('#searchbar').val()) {
                typingTimer = setTimeout(searchForPhrase, 200);
                logTimer = setTimeout(sendSearchLog, 2000)
                console.log("timer and logtimer added")
                logScheduled = true
            }
        }
    });

    function searchForPhrase(pagesShown = 7) {

        console.log("function started")

        $('[data-toggle="tooltip"]').tooltip('hide')

        searchQuery.size = pagesShown;
        searchQuery.query.bool.must[0].function_score.query.multi_match.query = document.getElementById('searchbar').value.toLowerCase();

        const showResults = function(data) {
            console.log(data)
            const showItems = []
            const numberOfItems = data.hits.total.value
            const suggestionBox = document.getElementById("autocombox")
            if (numberOfItems > 0) {

                if (numberOfItems > 0) {
                    showItems.push('<li class="notShown">' + numberOfItems + ' search results' + '</li>')
                } else if (numberOfItems === 1) {
                    showItems.push('<li class="notShown">' + numberOfItems + ' search result' + '</li>')
                }

                for (let i = 0; i < pagesShown && i < numberOfItems; i++) {
                    let text = undefined
                    let title = undefined
                    let branch = data.hits.hits[i].fields.branch
                    let branchClass = "searchResultNotBranched"
                    let branchLabel = ""

                    if (branch !== "notBranched") {
                        branchClass = "searchResultBranched"
                        let capitalBranch = branch.toString().charAt(0).toUpperCase() + branch.toString().slice(1)
                        let colorString = "#" + branchColors.get(capitalBranch).toString(16) + branchColors.get(capitalBranch).toString(16) + branchColors.get(capitalBranch).toString(16)
                        branchLabel = `<span id="branch${branch}" class="typeLabel branchLabel" style="color: ${colorString}; border-color: ${colorString};>${capitalBranch}</span>`
                    }

                    if (data.hits.hits[i].highlight != undefined) {
                        text = data.hits.hits[i].highlight.text
                        title = data.hits.hits[i].highlight.title
                    }
                    let preview = ""
                    if (typeof text !== 'undefined' && text) {
                        const textArray = text.toString().replace(/([.?!])\s*(?=[A-Z])/g, "$1|").split("|")
                        for (const sentence of textArray) {
                            if (sentence.includes("<strong>")) {
                                preview = preview.concat(" ", sentence)
                                if (preview.length > 115) {
                                    break;
                                }
                            }
                        }
                    } else {
                        preview = data.hits.hits[i].fields.alternative_text[0]
                    }

                    if (preview != undefined && preview) {
                        preview = preview.replaceAll("<strong>", "vQU0nfuawhKCT38fZDcSl0hnWMfXcrOq7VydIETdqMde8wmTzxnaZQ==")
                        preview = preview.replaceAll("</strong>", "7U3pTwKZCEwGRrgirF9cydI9cQWP2mzOiofD2Pl/HjFwxoekr5fRpg==")
                        preview = preview.replaceAll("<", "&lt;")
                        preview = preview.replaceAll(">", "&gt;")
                        preview = preview.replaceAll("vQU0nfuawhKCT38fZDcSl0hnWMfXcrOq7VydIETdqMde8wmTzxnaZQ==", "<strong>")
                        preview = preview.replaceAll("7U3pTwKZCEwGRrgirF9cydI9cQWP2mzOiofD2Pl/HjFwxoekr5fRpg==", "</strong>")
                    }

                    if (title == undefined || !title) {
                        title = data.hits.hits[i].fields.title[0]
                    }

                    setTimeout(setSearchItemOnclick.bind(null, data.hits.hits[i]._id, data.hits.hits[i].fields.title[0]), 130);

                    const parsedDate = Date.parse(data.hits.hits[i].fields.lastModificationDate[0])
                    const date = new Date(parsedDate)

                    let authorRaw = data.hits.hits[i].fields.author
                    let author = ""
                    if (typeof authorRaw == 'undefined' || !authorRaw) {
                        authorRaw = data.hits.hits[i].fields["wiki-metadata-create-user"]
                        author = "unknown"
                        if (typeof authorRaw != 'undefined' && authorRaw) {
                            author = authorRaw[0]
                        }
                    } else {
                        author = authorRaw[0]
                    }

                    let upvotesRaw = data.hits.hits[i].fields.upvotes
                    let upvotes = 0
                    if (typeof upvotesRaw != 'undefined' && upvotesRaw) {
                        upvotes = upvotesRaw[0]
                    }

                    let upkeepStatusRaw = data.hits.hits[i].fields["upkeep-status"]
                    let upkeepStatus = "unknown"
                    if (typeof upkeepStatusRaw != 'undefined' && upkeepStatusRaw) {
                        upkeepStatus = upkeepStatusRaw[0]
                    }

                    contentTriangleClass = "fas fa-exclamation-triangle conditionTriangle"
                    contentStatusArray = [data.hits.hits[i].fields.obsolete, data.hits.hits[i].fields.deprecated, data.hits.hits[i].fields.experimental, data.hits.hits[i].fields.planned, data.hits.hits[i].fields.outdated]
                    contentStatusValuesArray = ["obsolete", "deprecated", "experimental", "planned", "outdated"]
                    contentStatus = "" // TODO as array
                    filtredArray = contentStatusArray.filter(function(element, index) {
                        if (element != undefined && (element || element == "true")) {
                            contentStatus = contentStatusValuesArray[index]
                            return true;
                        } else {
                            return false;
                        }
                    });

                    if (contentStatus == "") {
                        contentStatus = "up-to-date"
                        contentTriangleClass = ""
                    }

                    let typeRaw = data.hits.hits[i].fields.type
                    let type = "other"
                    if (typeRaw != undefined && typeRaw) {
                        type = typeRaw[0]
                    }

                    showItems.push(`<div><span class="trigger-details searchResult" data-toggle="tooltip" data-toggle="tooltip" data-placement="left" 
                    data-html="true" title='<span class="tooltip-preview"><p>Last modification date: ${date.toLocaleDateString('en-GB', { timeZone: 'UTC' })}</p>
                    <p>Upkeep status: ${upkeepStatus} <i id="upkeep${upkeepStatus}" class="fa fa-circle"></i>
                    </p><p>Likes: ${upvotes}</p><p>Author: ${author}</p><p>Content: ${contentStatus} <i class="${contentTriangleClass}" style="margin-left: 5px;"></i></p></span>'><a class="aWithoutUnderline" href="${data.hits.hits[i].fields.url[0]}" 
                    id="${data.hits.hits[i]._id}site"><li class="list-group-item border-0 search-list-item"><i class="fas fa-align-left"></i>
                    <span class="font1 searchResultTitle ${branchClass}">&nbsp;${title}</span><span id="label${type}" class="typeLabel">${type.toUpperCase()}</span>${branchLabel}<i class="${contentTriangleClass}"></i><br><span class="font2">${preview}</span></li></a></span>
                    <span class="vote" id="${data.hits.hits[i]._id}up"><i class="fas fa-thumbs-up"></i></span></div>`);
                }

                const numberOfNotShown = numberOfItems - pagesShown

                if (numberOfNotShown === 1) {
                    showItems.push('<li class="notShown" id="moreResults"> additional ' + numberOfNotShown + ' result not shown (click here for more results)' + '</li>')
                } else if (numberOfNotShown > 0) {
                    showItems.push('<li class="notShown" id="moreResults"> additional ' + numberOfNotShown + ' results not shown (click here for more results)' + '</li>')
                }

                suggestionBox.innerHTML = showItems.join("")
                suggestionBox.style.display = "table";

                $("#moreResults").click(function() {
                    searchForPhrase(pagesShown + 7)
                });

            } else {
                suggestionBox.innerHTML = ""
                suggestionBox.style.display = "none";
            }

            $('[data-toggle="tooltip"]').tooltip();

            setTimeout(setHighlighting, 30);

        }

        OSrequest("GET", "https://searchtest.evolveum.com/docs,mpbook/_search", searchQuery, true, showResults)
    }

    function setHighlighting() {
        let listItems = document.querySelectorAll("#searchbar, .aWithoutUnderline");

        // Set up a counter to keep track of which <li> is selected
        let currentLI = 0;

        // Initialize first li as the selected (focused) one:
        listItems[currentLI].classList.add("highlightSearch");

        // Set up a key event handler for the document
        document.addEventListener("keydown", function(event) {
            // Check for up/down key presses
            switch (event.keyCode) {
                case 38: // Up arrow    
                    // Remove the highlighting from the previous element
                    listItems[currentLI].classList.remove("highlightSearch");
                    if (listItems[currentLI].className == "aWithoutUnderline") {
                        listItems[currentLI].parentElement.parentElement.classList.remove("highlightParentSearch");
                    }
                    listItems[currentLI].blur()

                    currentLI = currentLI > 0 ? --currentLI : 0; // Decrease the counter      
                    listItems[currentLI].classList.add("highlightSearch"); // Highlight the new element
                    if (listItems[currentLI].id != "searchbar") {
                        listItems[currentLI].parentElement.parentElement.classList.add("highlightParentSearch");
                    }
                    listItems[currentLI].focus({ focusVisible: true })
                    break;
                case 40: // Down arrow
                    // Remove the highlighting from the previous element
                    listItems[currentLI].classList.remove("highlightSearch");
                    if (listItems[currentLI].className == "aWithoutUnderline") {
                        listItems[currentLI].parentElement.parentElement.classList.remove("highlightParentSearch");
                    }
                    listItems[currentLI].blur()

                    currentLI = currentLI < listItems.length - 1 ? ++currentLI : listItems.length - 1; // Increase counter 
                    listItems[currentLI].classList.add("highlightSearch"); // Highlight the new element
                    if (listItems[currentLI].id != "searchbar") {
                        listItems[currentLI].parentElement.parentElement.classList.add("highlightParentSearch");
                    }
                    listItems[currentLI].focus({ focusVisible: true })
                    break;
            }
        });
    }

    function sendSearchLog(id, title) {
        logScheduled = false
        const date = new Date();
        let logPayload = {
            "@timestamp": date.toISOString(),
            "querylength": document.getElementById('searchbar').value.toLowerCase().length,
            "query": document.getElementById('searchbar').value.toLowerCase()
        }
        OSrequest("POST", "https://searchtest.evolveum.com/finalsearchlogs/_doc/", logPayload, true)
    }

    function setSearchItemOnclick(id, title) {

        let up = document.getElementById(id + "up")
        up.onclick = function() {
            let modify = "+"

            if ($(this).prop("classList").contains('on')) {
                modify = "-"
            }

            let queryUpvote = {
                script: {
                    source: "if (ctx._source['upvotes'] != null) { ctx._source['upvotes'] " + modify + "= 1 } else { ctx._source['upvotes'] = 1 }"
                }
            }

            OSrequest("POST", "https://searchtest.evolveum.com/docs/_update/" + id + "?refresh", queryUpvote, true)

            $(this).toggleClass('on');
        };

        // TODO for now, we suppose that cases in which the user did not select "open in a new tab" or just triggered the "mousedown" event and did not click are statistically insignificant
        let site = document.getElementById(id + "site")
        site.addEventListener("mousedown", (event) => {
            if (event.button == 0 || event.button == 2) {

                const date = new Date();

                if (logScheduled) {
                    clearTimeout(logTimer);
                    logTimer = null;
                    let logPayload = {
                        "@timestamp": date.toISOString(),
                        "querylength": document.getElementById('searchbar').value.toLowerCase().length,
                        "query": document.getElementById('searchbar').value.toLowerCase()
                    }
                    OSrequest("POST", "https://searchtest.evolveum.com/finalsearchlogs/_doc/", logPayload, true)
                    logScheduled = false
                    console.log("logtimer removed")
                }

                console.log("mousedown" + event.button);

                let queryClick = {
                    "title": title,
                    "doc_id": id,
                    "@timestamp": date.toISOString(),
                    "querylength": document.getElementById('searchbar').value.toLowerCase().length,
                    "clickquery": document.getElementById('searchbar').value.toLowerCase()
                }

                event.button == 0 ? OSrequest("POST", "https://searchtest.evolveum.com/click_logs/_doc/", queryClick, false) : OSrequest("POST", "https://searchtest.evolveum.com/click_logs/_doc/", queryClick, true);
            }
        });
    }

})();