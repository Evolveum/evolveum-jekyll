(function() {

    let charsBeforeSearch = "";

    $("#search-modal").on('shown.bs.modal', function() {
        console.log('triggered')
        console.log(charsBeforeSearch + " second")
        document.getElementById('searchbar').value = charsBeforeSearch;
        $('#searchbar').trigger('focus')
        console.log(document.getElementById('searchbar').value)
        charsBeforeSearch = "";
    });

    $(document).on('keyup', function(e) {
        if (e.key.length == 1) {
            charsBeforeSearch += e.key;
            console.log(charsBeforeSearch)
            if (!$("#search-modal").hasClass('show')) {
                $("#search-modal").modal()
            }
        }
    });

    $("#search-modal").on('hidden.bs.modal', function() {
        document.getElementById("autocombox").innerHTML = "";
        document.getElementById("autocombox").style.display = "none";
        document.getElementById('searchToggle').value = "";
        document.getElementById('searchbar').value = "";
        charsBeforeSearch = "";
    });
})();

(function() {

    function OSrequest(method, url, query, username, password, async, callback) {
        $.ajax({
            method: method,
            url: url,
            crossDomain: true,
            xhrFields: {
                withCredentials: true
            },
            headers: {
                "Authorization": "Basic " + btoa(username + ":" + password)
            },
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

    OSrequest("GET", "https://osdocs.example.com/search_settings/_doc/1", undefined, "search", "search", true, setSearchQuery)

    function setSearchQuery(data) {
        searchQuery = {
            query: {
                function_score: {
                    script_score: {
                        script: { // TODO update script
                            source: `
                                double totalScore = _score;
                                if (doc.upvotes.size()!=0) {
                                    totalScore = totalScore*(1+${data._source.multipliers.upvotes}*doc.upvotes.value/100);
                                }
                                if (doc['upkeep-status.keyword'].size()!=0) {
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
                                if (doc.lastModificationDate.size()!=0) {
                                    double timestampNow = (double)new Date().getTime();
                                    totalScore = totalScore*Math.max(${data._source.values.last_modification_min}, ${data._source.multipliers.last_modification_im}/(1+(timestampNow - doc.lastModificationDate.value.getMillis())/${data._source.values.last_modification * 24 * 60 * 60 * 1000}.0))
                                } else {
                                    totalScore = totalScore*${data._source.multipliers.age_absent};
                                }
                                if (doc.obsolete.size()!=0) {
                                    if (doc.obsolete.value == true) {
                                        totalScore = totalScore*${data._source.multipliers.obsolete_true};
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
                                "preview^0.1"
                            ],
                            fuzziness: "AUTO",
                            prefix_length: 2,
                        }
                    }
                }

            },
            highlight: {
                pre_tags: [
                    "<strong>"
                ],
                post_tags: [
                    "</strong>"
                ],
                fields: {
                    title: {},
                    text: {},
                    preview: {}
                }
            }
        }
    }

    var typingTimer = null;

    $('#searchbar').keydown(function() {
        if (typingTimer) {
            clearTimeout(typingTimer);
            typingTimer = null;
            console.log("timer removed")
        }
        if ($('#searchbar').val()) {
            typingTimer = setTimeout(searchForPhrase, 200);
            console.log("timer added")
        }
    });

    function searchForPhrase(pagesShown = 7) {

        console.log("function started")

        searchQuery.size = pagesShown;
        searchQuery.query.function_score.query.multi_match.query = document.getElementById('searchbar').value.toLowerCase();

        const showResults = function(data) {
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
                    const text = data.hits.hits[i].highlight.text
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
                        preview = data.hits.hits[i].highlight.preview
                        console.log("notext " + preview + " test " + data.hits.hits[i]._source.preview)
                    }

                    setTimeout(setSearchItemOnclick.bind(null, data.hits.hits[i]._id, data.hits.hits[i]._source.title), 30);

                    const parsedDate = Date.parse(data.hits.hits[i]._source.lastModificationDate)
                    const date = new Date(parsedDate)
                    let author = data.hits.hits[i]._source.author
                    if (typeof author == 'undefined' || !author) {
                        author = data.hits.hits[i]._source["wiki-metadata-create-user"]
                    }

                    showItems.push(`<div><span class="trigger-details" style="display: inline-block;width: 430px" data-toggle="tooltip" data-placement="left" 
                    data-html="true" title='<span class="tooltip-preview"><p>Last modification date: ${date.toLocaleDateString('en-GB', { timeZone: 'UTC' })}</p>
                    <p>Upkeep status: ${data.hits.hits[i]._source["upkeep-status"]} <i id="upkeep${data.hits.hits[i]._source["upkeep-status"]}" class="fa fa-circle"></i>
                    </p><p>Likes: ${data.hits.hits[i]._source.upvotes}</p><p>Author: ${author}</p></span>'><a href="${data.hits.hits[i]._source.url}" 
                    id="${data.hits.hits[i]._id}site"><li class="list-group-item border-0 search-list-item"><i class="fas fa-align-left"></i>
                    <span class="font1">&nbsp;${data.hits.hits[i].highlight.title}<br></span><span class="font2">${preview}</span></li></a></span>
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
        }

        OSrequest("POST", "https://osdocs.example.com/docs/_search", searchQuery, "search", "search", true, showResults)
    }

    function setSearchItemOnclick(id, title) {

        $("#" + id + "up").click(function() {
            let modify = "+"

            if ($(this).prop("classList").contains('on')) {
                modify = "-"
            }

            let queryUpvote = {
                script: {
                    source: "if (ctx._source['upvotes'] != null) { ctx._source['upvotes'] " + modify + "= 1 } else { ctx._source['upvotes'] = 1 }"
                }
            }

            OSrequest("POST", "https://osdocs.example.com/docs/_update/" + id + "?refresh", queryUpvote, "upvotes", "upvotes", true)

            $(this).toggleClass('on');
        });

        // TODO for now, we suppose that cases in which the user did not select "open in a new tab" or just triggered the "mousedown" event and did not click are statistically insignificant
        $("#" + id + "site").on('mousedown', function(ev) {
            if (ev.button == 0 || ev.button == 2) {
                console.log("mousedown" + ev.button);

                const date = new Date();

                let queryClick = {
                    "title": title,
                    "doc_id": id,
                    "timestamp": date.toISOString(),
                    "query": document.getElementById('searchbar').value.toLowerCase()
                }

                ev.button == 0 ? OSrequest("POST", "https://osdocs.example.com/click_logs/_doc/", queryClick, "clicklog", "clicklog", false) : OSrequest("POST", "https://osdocs.example.com/click_logs/_doc/", queryClick, "clicklog", "clicklog", true);
            }
        });
    }

})();