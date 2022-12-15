(function() {

    let letters = new Set(["Guide", "Reference", "Developer", "Other"]);

    $('.oval').click(function() {
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

    $("#search-modal").on('shown.bs.modal', function() {
        console.log('triggered')
        $('#searchbar').trigger('focus')
        console.log(document.getElementById('searchbar').value)
    });

    $(document).on('keydown', function(e) {
        if (e.key.length == 1 && !e.ctrlKey) {
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
    });

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

    OSrequest("GET", "https://osdocs.lab.evolveum.com/search_settings/_doc/1", undefined, "search", "YvHY6hR8Zets+fGQ", true, setSearchQuery)

    function setSearchQuery(data) {
        searchQuery = {
            query: {
                bool: {
                    filter: [{
                        terms: {
                            "type.keyword": Array.from(letters)
                        }
                    }],
                    must: [{
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
                                        if (doc.deprecated.size()!=0) {
                                            if (doc.deprecated.value == true) {
                                                totalScore = totalScore*${data._source.multipliers.deprecated};
                                            }
                                        }
                                        if (doc.experimental.size()!=0) {
                                            if (doc.experimental.value == true) {
                                                totalScore = totalScore*${data._source.multipliers.experimental};
                                            }
                                        }
                                        if (doc.planned.size()!=0) {
                                            if (doc.planned.value == true) {
                                                totalScore = totalScore*${data._source.multipliers.planned};
                                            }
                                        }
                                        if (doc.outdated.size()!=0) {
                                            if (doc.outdated.value == true) {
                                                totalScore = totalScore*${data._source.multipliers.outdated};
                                            }
                                        }
                                        if (doc.obsolete.size()!=0) {
                                            if (doc.obsolete.value == true) {
                                                totalScore = totalScore*${data._source.multipliers.obsolete};
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

        $('[data-toggle="tooltip"]').tooltip('hide')

        searchQuery.size = pagesShown;
        searchQuery.query.bool.must[0].function_score.query.multi_match.query = document.getElementById('searchbar').value.toLowerCase();

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
                        preview = data.hits.hits[i]._source.text.substring(0, 115)
                        if (preview == undefined || !preview) {
                            preview = data.hits.hits[i]._source.alternative_text
                        }
                    }

                    if (preview != undefined && preview) {
                        preview.replaceAll("<", "&lt;|")
                        preview.replaceAll(">", "|&gt;")
                    }

                    let title = data.hits.hits[i].highlight.title

                    if (title == undefined || !title) {
                        title = data.hits.hits[i]._source.title
                    }

                    setTimeout(setSearchItemOnclick.bind(null, data.hits.hits[i]._id, data.hits.hits[i]._source.title), 30);

                    const parsedDate = Date.parse(data.hits.hits[i]._source.lastModificationDate)
                    const date = new Date(parsedDate)

                    let author = data.hits.hits[i]._source.author
                    if (typeof author == 'undefined' || !author) {
                        author = data.hits.hits[i]._source["wiki-metadata-create-user"]
                        if (typeof author == 'undefined' || !author) {
                            author = "unknown"
                        }
                    }

                    let upvotes = data.hits.hits[i]._source.upvotes
                    if (typeof upvotes == 'undefined' || !upvotes) {
                        upvotes = 0
                    }

                    let upkeepStatus = data.hits.hits[i]._source["upkeep-status"]
                    if (typeof upkeepStatus == 'undefined' || !upkeepStatus) {
                        upkeepStatus = "unknown"
                    }

                    contentTriangleClass = "fas fa-exclamation-triangle conditionTriangle"
                    contentStatusArray = [data.hits.hits[i]._source.obsolete, data.hits.hits[i]._source.deprecated, data.hits.hits[i]._source.experimental, data.hits.hits[i]._source.planned, data.hits.hits[i]._source.outdated]
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

                    showItems.push(`<div><span class="trigger-details" style="display: inline-block;width: 430px" data-toggle="tooltip" data-placement="left" 
                    data-html="true" title='<span class="tooltip-preview"><p>Last modification date: ${date.toLocaleDateString('en-GB', { timeZone: 'UTC' })}</p>
                    <p>Upkeep status: ${upkeepStatus} <i id="upkeep${upkeepStatus}" class="fa fa-circle"></i>
                    </p><p>Likes: ${upvotes}</p><p>Author: ${author}</p><p>Content: ${contentStatus} <i class="${contentTriangleClass}" style="margin-left: 5px;"></i></p></span>'><a class="aWithoutUnderline" href="${data.hits.hits[i]._source.url}" 
                    id="${data.hits.hits[i]._id}site"><li class="list-group-item border-0 search-list-item"><i class="fas fa-align-left"></i>
                    <span class="font1">&nbsp;${title}</span><span id="label${data.hits.hits[i]._source.type}" class="typeLabel">${data.hits.hits[i]._source.type.toUpperCase()}</span><i class="${contentTriangleClass}"></i><br><span class="font2">${preview}</span></li></a></span>
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

        OSrequest("POST", "https://osdocs.lab.evolveum.com/docs/_search", searchQuery, "search", "YvHY6hR8Zets+fGQ", true, showResults)
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

            OSrequest("POST", "https://osdocs.lab.evolveum.com/docs/_update/" + id + "?refresh", queryUpvote, "upvotes", "VYIWUwo5sJ/plOIC", true)

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

                ev.button == 0 ? OSrequest("POST", "https://osdocs.lab.evolveum.com/click_logs/_doc/", queryClick, "clicklog", "YBSbhSKDzBxGCXtl", false) : OSrequest("POST", "https://osdocs.lab.evolveum.com/click_logs/_doc/", queryClick, "clicklog", "YBSbhSKDzBxGCXtl", true);
            }
        });
    }

})();