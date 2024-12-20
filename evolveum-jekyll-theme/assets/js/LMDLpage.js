---
---
(function() {

    let allSearchCategory = ["Guide", "Book", "Reference", "Developer", "Other"]
    let searchCategory = new Set([]);
    let allImportance = ["Created", "Removed", "Major", "Significant", "Minor"]
    let importance = new Set([]);
    let allSearchIn = ["Title", "Text", "Commit message"]
    let searchIn = new Set([])
    let authors = new Set([])
    {% if site.environment.name contains "docs" %}
    let filterBranches = new Set([])
    {% endif %}
    let allAuthors = []
    var shouldIgnoreScroll = false;

    let initialSearchQuery = {
        query: {
            bool: {
                must_not: [{
                    term: {
                        "effectiveVisibility": "hidden"
                    }
                },
                {
                    term: {
                        "visibility": "hidden"
                    }
                }
                ]
            }
        },
        fields: [
            "commitMessage",
            "title",
            "date",
            "upkeep-status",
            "obsolete",
            "deprecated",
            "experimental",
            "planned",
            "outdated",
            "contentType",
            "importance",
            "author",
            "url",
            "id",
            "gitUrl"{% if site.environment.name contains "docs" %},
            "branch"{% endif %}
        ],
        _source: false,
        size: 30,
        sort: [{
            date: {
                order: "desc"
            }
        }]
    }

    let afterSearchQuery = {
        query: {
            bool: {
                must: [{
                        bool: {
                            filter: [{
                                terms: {
                                    "importance.keyword": allImportance
                                }
                            }, {
                                terms: {
                                    "author.keyword": []
                                }
                            }, {
                                terms: {
                                    "contentType.keyword": allSearchCategory
                                }
                            }]
                        }
                    }, {
                        bool: {
                            should: []
                        }
                    }

                ],
                must_not: [{
                    term: {
                        "effectiveVisibility": "hidden"
                    }
                },
                {
                    term: {
                        "visibility": "hidden"
                    }
                }]
            }
        },
        fields: [
            "commitMessage",
            "title",
            "date",
            "upkeep-status",
            "obsolete",
            "deprecated",
            "experimental",
            "planned",
            "outdated",
            "contentType",
            "importance",
            "author",
            "url",
            "id",
            "gitUrl"{% if site.environment.name contains "docs" %},
            "branch"{% endif %}
        ],
        _source: false,
        size: 30,
        from: 0,
        sort: [{
            date: {
                order: "desc"
            }
        }]
    }

    function OSrequest(method, url, query, async, callback) {
        $.ajax({
            method: method,
            url: url,
            {% if site.environment.name contains "guide" %}
            headers: {
                "Authorization": "Basic " + btoa("{{ site.environment.osUsername }}" + ":" + "{{ site.environment.osPassword }}")
            },
            {% endif %}
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

    const updateList = function(data) {
        let listbox = document.getElementById("listOfUpdatedPages")
        let listitems = []
        console.log(data)
        for (let i = 0; i < data.hits.hits.length && i < data.hits.total.value; i++) { // TODO
            let commitMessageRaw = data.hits.hits[i].fields.commitMessage;
            let commitMessage = ""
            if (commitMessageRaw != undefined && commitMessageRaw) {
                commitMessage = commitMessageRaw[0]
            }
            let unknownStatus = "";

            {% if site.environment.name contains "docs" %}
            let contentVersion = "Not versioned"
            let contentDisplayVersion = "Not versioned"
            let versionColor = "#CACACA"

            if (data.hits.hits[i].fields.branch != undefined) {
                contentVersion = data.hits.hits[i].fields.branch[0]
                if (contentVersion != "Not versioned") {
                    let contentVersionWithoutDocs = contentVersion.replace("docs/", "")
                    contentDisplayVersion = DOCSBRANCHMAP[contentVersionWithoutDocs]
                    versionColor = DOCSBRANCHESCOLORS.get(contentDisplayVersion)
                }
            }
            {% endif %}

            if (commitMessage != undefined && commitMessage) {
                commitMessage = commitMessage.replaceAll("<", "&lt;")
                commitMessage = commitMessage.replaceAll(">", "&gt;")
            }

            let title = ""
            let titleRaw = data.hits.hits[i].fields.title

            if (data.hits.hits[i].highlight == undefined) {
                if (titleRaw != undefined && titleRaw) {
                    title = titleRaw[0]
                }
            } else {
                title = data.hits.hits[i].highlight.title
            }

            let rawDate = data.hits.hits[i].fields.date[0]
            const parsedDate = Date.parse(rawDate)
            const date = new Date(parsedDate)

            let upkeepStatusRaw = data.hits.hits[i].fields["upkeep-status"]
            let upkeepStatus = "unknown"
            if (typeof upkeepStatusRaw == 'undefined' || !upkeepStatusRaw) {
                unknownStatus = "&nbsp;unknown"
            } else {
                upkeepStatus = upkeepStatusRaw[0]
            }

            contentTriangleClass = ""
            contentStatusArray = [data.hits.hits[i].fields.obsolete, data.hits.hits[i].fields.deprecated, data.hits.hits[i].fields.experimental, data.hits.hits[i].fields.planned, data.hits.hits[i].fields.outdated]
            contentStatusValuesArray = ["obsolete", "deprecated", "experimental", "planned", "outdated"]
            contentStatus = "" // TODO as array
            filtredArray = contentStatusArray.filter(function(element, index) {
                if (element != undefined && (element == "true")) {
                    contentStatus = contentStatusValuesArray[index]
                    return true;
                } else {
                    return false;
                }
            });

            if (contentStatus != "") {
                contentTriangleClass = "fas fa-exclamation-triangle conditionTriangle LMDLelementTooltip"
            }

            let contentTypeRaw = data.hits.hits[i].fields.contentType;
            let contentType = ""
            if (typeof contentTypeRaw != 'undefined' && contentTypeRaw) {
                contentType = contentTypeRaw[0]
            }

            let impactOfChangeRaw = data.hits.hits[i].fields.importance
            let impactOfChange = ""
            if (typeof impactOfChangeRaw != 'undefined' && impactOfChangeRaw) {
                impactOfChange = impactOfChangeRaw[0]
            }

            let authorRaw = data.hits.hits[i].fields.author
            let author = ""
            if (typeof authorRaw != 'undefined' && authorRaw) {
                author = authorRaw[0]
            }

            author = author.replace(/<.*>/, "")

            let parsedTitle = title.replace(/[\W_]+/g, "")

            listitems.push(`<tr>
        <th class="LMDLtitle" scope="row"><a href="${data.hits.hits[i].fields.url[0]}" class="LMDLelementTooltip" data-toggle="tooltip" data-html="true" data-original-title='<span>Upkeep status:&nbsp;<i id="upkeep${upkeepStatus}" class="fa fa-circle LMDLupkeep${upkeepStatus}"></i>${unknownStatus}</span>'>${title}</a>&nbsp;<a class="LMDLtitleGithubLink" href="${data.hits.hits[i].fields.gitUrl[0]}">history&nbsp;<i class="fab fa-github"></i></a><i data-toggle="tooltip" title="${contentStatus}" class="${contentTriangleClass}"></th>
        {% if site.environment.name contains "docs" %}<td class="LMDLcategory${contentVersion} LMDLcategory" style="color:${versionColor};">${contentDisplayVersion}</td>{% endif %}
        <td class="LMDLcategory${contentType} LMDLcategory">${contentType.toUpperCase()}</td>
        <td class="tableCentered LMDLimpact${impactOfChange} LMDLimpact">${impactOfChange.toUpperCase()}</td>
        <td class="tableCentered LMDLauthor">${author}</td>
        <td class="tableCentered LMDLdate">${date.toLocaleDateString('en-GB', { timeZone: 'UTC' })}</td>
        <td class="LMDLmessage">${commitMessage}</td></tr>
        <tr id="${data.hits.hits[i].fields.id[0]}${parsedTitle}header" class="LMDLexpandedHeaderRow"><td scope="row" class="tableCentered LMDLexpandedHeader LMDLexpandedCategory">Category</td>
        <td scope="row" class="tableCentered LMDLtooltipTh LMDLexpandedHeader LMDLexpandedImpactHeader" data-toggle="tooltip" data-html="true" 
        title="<div><span>Extend to which the page had been modified</span><br><span><span class=&quot;LMDLimpactMajor&quot;>Major</span> - more than 30% of lines were edited</span><br><span><span class=&quot;LMDLimpactSignificant&quot;>Significant</span> - more than 10% and less than 30% of lines were edited</span><br><span><span class=&quot;LMDLimpactMinor&quot;>Minor</span> - less than 10% of lines were edited</span></div>">Impact of change&nbsp;<i style="font-size: 0.8rem;" class="fas fa-question-circle"></i></td>
        <td scope="row" class="tableCentered LMDLexpandedHeader LMDLexpandedAuthor">Author</td></tr>
        <tr id="${data.hits.hits[i].fields.id[0]}${parsedTitle}detail" class="LMDLexpandedDetailRow"><td scope="row" class="LMDLcategoryGuide LMDLcategory LMDLexpandedDetail LMDLexpandedCategoryCell">GUIDE</td>
        <td class="tableCentered LMDLimpactMinor LMDLimpact LMDLexpandedDetail LMDLexpandedImpactCell">MINOR</td>
        <td class="tableCentered LMDLauthor LMDLexpandedDetail LMDLexpandedAuthorCell">Jan Mederly</td></tr>
        <tr id="${data.hits.hits[i].fields.id[0]}${parsedTitle}" class='LMDLmoreSmallDetails'><td colspan="3" class="notShown LMDLmoreSmallDetailsTd">Show more&nbsp;<i class="fas fa-angle-down LMDLmoreSmallDetailsI"></i></td></tr>`);
            setTimeout(setMoreDetailsOnClick.bind(null, `${data.hits.hits[i].fields.id[0]}${parsedTitle}`), 100);
        }
        listbox.innerHTML += listitems.join("")
        $(".LMDLelementTooltip").tooltip();
    }

    function searchLMDP(beginningIndex = 0) {
        let pagesShown = 30
        afterSearchQuery.size = pagesShown
        afterSearchQuery.from = beginningIndex
        afterSearchQuery.query.bool.must[1].bool.should = []

        if (document.getElementById('LMDLsearchbar').value.toLowerCase() != undefined && document.getElementById('LMDLsearchbar').value.toLowerCase() != "") {
            if (searchIn.has("Title") || searchIn.size == 0) {
                afterSearchQuery.query.bool.must[1].bool.should.push({
                    bool: {
                        filter: [{
                            term: {
                                title: document.getElementById('LMDLsearchbar').value.toLowerCase()
                            }
                        }]
                    }
                });
            }
            if (searchIn.has("Text") || searchIn.size == 0) {
                afterSearchQuery.query.bool.must[1].bool.should.push({
                    bool: {
                        filter: [{
                            term: {
                                text: document.getElementById('LMDLsearchbar').value.toLowerCase()
                            }
                        }]
                    }
                });
            }
            if (searchIn.has("Commit message") || searchIn.size == 0) {
                afterSearchQuery.query.bool.must[1].bool.should.push({
                    bool: {
                        filter: [{
                            term: {
                                commitMessage: document.getElementById('LMDLsearchbar').value.toLowerCase()
                            }
                        }]
                    }
                });
            }
        } else(
            afterSearchQuery.query.bool.must[1].bool.should = [{
                "exists": {
                    field: "commitMessage"
                }
            }]
        )

        if (beginningIndex == 0) {
            let listbox = document.getElementById("listOfUpdatedPages")
            listbox.innerHTML = ""
        }

        $(window).off('scroll');

        scrollEvent = function() {
            if ($(window).scrollTop() >= $(document).height() - $(window).height() - 10) {
                if (shouldIgnoreScroll) {
                    return;
                }
                shouldIgnoreScroll = true;
                setTimeout(() => {
                    shouldIgnoreScroll = false;
                }, 1200);
                searchLMDP(beginningIndex + 30)
            }
        }
        $(window).scroll(scrollEvent); // TODO DO NOT REPEAT


        {% if site.environment.name contains "docs" %}
        OSrequest("POST", "https://{{ site.environment.searchUrl }}/docs_commits/_search", afterSearchQuery, true, updateList)
        {% else %}
        OSrequest("POST", "https://{{ site.environment.searchUrl }}/guide_commits/_search", afterSearchQuery, true, updateList)
        {% endif %}
    }

    $(document).ready(function() {
        setLMDLSearchIn()
        {% if site.environment.name contains "docs" %}
        setLMDLVersion()
        {% endif %}
        setLMDLCategory()
        setLMDLImpact()

        $("#LMDLsearchButton").click(function() {
            searchLMDP();
        });

        $(".LMDLtooltipTh").tooltip()

        {% if site.environment.name contains "docs" %}
        OSrequest("POST", "https://{{ site.environment.searchUrl }}/docs_commits/_search", initialSearchQuery, true, updateList)
        {% else %}
        OSrequest("POST", "https://{{ site.environment.searchUrl }}/guide_commits/_search", initialSearchQuery, true, updateList)
        {% endif %}

        let request = {
            "aggs": {
                "authors": {
                    "terms": {
                        "field": "author.keyword",
                        "order": {
                            "_key": "asc"
                        },
                        "size": 1000
                    }

                }
            },
            "size": 0
        }

        {% if site.environment.name contains "docs" %}
        OSrequest("POST", "https://{{ site.environment.searchUrl }}/docs_commits/_search", request, true, setAuthors)
        {% else %}
        OSrequest("POST", "https://{{ site.environment.searchUrl }}/guide_commits/_search", request, true, setAuthors)
        {% endif %}

        $(window).scroll(function() {
            if ($(window).scrollTop() >= $(document).height() - $(window).height() - 10) {
                if (shouldIgnoreScroll) {
                    return;
                }
                shouldIgnoreScroll = true;
                setTimeout(() => {
                    shouldIgnoreScroll = false;
                }, 1200);
                searchLMDP(30)
            }
        });

        $('.LMDLDatePickerButton').daterangepicker({
            "showDropdowns": true,
            ranges: {
                'Today': [moment(), moment()],
                'Yesterday': [moment().subtract(1, 'days'), moment().subtract(1, 'days')],
                'Last 7 Days': [moment().subtract(6, 'days'), moment()],
                'Last 30 Days': [moment().subtract(29, 'days'), moment()],
                'This Month': [moment().startOf('month'), moment().endOf('month')],
                'Last Month': [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')]
            },
            autoUpdateInput: false,
            locale: {
                cancelLabel: 'Clear'
            },
            "alwaysShowCalendars": true,
            "linkedCalendars": false
        })

        $('.LMDLDatePickerButton').on('apply.daterangepicker', function(ev, picker) {
            document.getElementById("LMDLPickedDate").innerHTML = picker.startDate.format('DD/MM/YYYY') + ' - ' + picker.endDate.format('DD/MM/YYYY')
            document.getElementById("LMDLPickedDate").style.color = "#000"
            afterSearchQuery.query.bool.must[0].bool.filter.push({
                range: {
                    "date": {
                        gte: picker.startDate.format('YYYY-MM-DD'),
                        lte: picker.endDate.format('YYYY-MM-DD')
                    }
                }
            })
            searchLMDP()
        });

        $('.LMDLDatePickerButton').on('cancel.daterangepicker', function(ev, picker) {
            document.getElementById("LMDLPickedDate").innerHTML = 'Pick a date range'
            document.getElementById("LMDLPickedDate").style.color = "#909090"
            afterSearchQuery.query.bool.must[0].bool.filter.pop()
            searchLMDP()
        });
    });

    $('#LMDLsearchbar').on('focus', function() {
        $(document).off('keydown');
    });
    $('#LMDLsearchbar').on('blur', function() {
        $(document).on('keydown', function(e) {
            if (e.key.length == 1 && !e.ctrlKey) {
                if (!$("#search-modal").hasClass('show')) {
                    $("#search-modal").modal()
                }
            }
        });
    });

    function setLMDLSearchIn() {
        $('#selectpickersearchin').selectpicker();
        $('#selectpickersearchin').selectpicker('deselectAll');
        $('#selectpickersearchin').on('changed.bs.select', function(e, clickedIndex, isSelected, previousValue) {
            if (isSelected) {
                searchIn.add(allSearchIn[clickedIndex])
            } else {
                searchIn.delete(allSearchIn[clickedIndex])
            }
        });
    }

    {% if site.environment.name contains "docs" %}
    function setLMDLVersion() {
        let branchList = []
        for (let i = 0; i < DOCSBRANCHESDISPLAYNAMES.length; i++) {
            branchList.push("<option style=\"color: " + DOCSBRANCHESCOLORS.get(DOCSBRANCHESDISPLAYNAMES[i]) + ";\">" + DOCSBRANCHESDISPLAYNAMES[i] + "</option>")
            console.log("<option style=\"color: " + DOCSBRANCHESCOLORS.get(DOCSBRANCHESDISPLAYNAMES[i]) + ";\">" + DOCSBRANCHESDISPLAYNAMES[i] + "</option>")
        }
        let selectObjects = document.getElementById("selectpickerversion")
        selectObjects.innerHTML = branchList.join("")
            //afterSearchQuery.query.bool.must[0].bool.filter[1].terms["author.keyword"] = allAuthors
        $('#selectpickerversion').selectpicker();
        $('#selectpickerversion').selectpicker('deselectAll');
        $('#selectpickerversion').on('changed.bs.select', function(e, clickedIndex, isSelected, previousValue) {
            if (isSelected) {
                filterBranches.add(DOCSORIGINALBRANCHMAP[DOCSBRANCHMAP[DOCSBRANCHESDISPLAYNAMES[clickedIndex]]]) //TODO improve - not very pretty
            } else {
                filterBranches.delete(DOCSORIGINALBRANCHMAP[DOCSBRANCHMAP[DOCSBRANCHESDISPLAYNAMES[clickedIndex]]])
            }

            if (filterBranches.size == 0) {
                afterSearchQuery.query.bool.must[0].bool.filter.pop()
            } else {
                afterSearchQuery.query.bool.must[0].bool.filter.push({
                    terms: {
                        "branch.keyword": Array.from(filterBranches)
                    }
                })
            }
            searchLMDP()
        }).on('loaded.bs.select', function(e) {
            let parent = $('#selectpickerversion')[0].parentElement
            parent.id = "LMDLversionPicker"
        });
    }{% endif %}

    function setLMDLCategory() {
        $('#selectpickercategory').selectpicker();
        $('#selectpickercategory').selectpicker('deselectAll');
        $('#selectpickercategory').on('changed.bs.select', function(e, clickedIndex, isSelected, previousValue) {
            if (isSelected) {
                searchCategory.add(allSearchCategory[clickedIndex])
            } else {
                searchCategory.delete(allSearchCategory[clickedIndex])
            }

            if (searchCategory.size == 0) {
                afterSearchQuery.query.bool.must[0].bool.filter[2].terms["contentType.keyword"] = allSearchCategory
            } else {
                afterSearchQuery.query.bool.must[0].bool.filter[2].terms["contentType.keyword"] = Array.from(searchCategory)
            }
            searchLMDP()
        }).on('loaded.bs.select', function(e) {
            let parent = $('#selectpickercategory')[0].parentElement
            parent.id = "LMDLcategoryPicker"
        });
    }

    function setLMDLImpact() {
        $('#selectpickerimpact').selectpicker();
        $('#selectpickerimpact').selectpicker('deselectAll');
        $('#selectpickerimpact').on('changed.bs.select', function(e, clickedIndex, isSelected, previousValue) {
            if (isSelected) {
                importance.add(allImportance[clickedIndex])
            } else {
                importance.delete(allImportance[clickedIndex])
            }

            if (importance.size == 0) {
                afterSearchQuery.query.bool.must[0].bool.filter[0].terms["importance.keyword"] = allImportance
            } else {
                afterSearchQuery.query.bool.must[0].bool.filter[0].terms["importance.keyword"] = Array.from(importance)
            }
            searchLMDP()
        }).on('loaded.bs.select', function(e) {

            // save the element
            let el = $(this);

            console.log(el)

            console.log(el.data('selectpicker'))

            // the list items with the options
            let lis = el.data('selectpicker').selectpicker.main.data;

            lis.forEach(function(i) {
                let optionLi = i.element
                let optionA = optionLi.children[0]
                let optionText = optionLi.innerText
                let tooltipText = ""

                switch (optionText) {
                    case "Major":
                        tooltipText = "More than 30% of lines have been edited"
                        break;
                    case "Significant":
                        tooltipText = "More than 10% and less than 30% of lines have been edited"
                        break;
                    case "Minor":
                        tooltipText = "Less than 10% of lines have been edited"
                        break;
                }

                $(optionA).tooltip({
                    'title': tooltipText,
                    'placement': 'right',
                    'container': 'body',
                    'boundary': 'window'
                });

            });

            let parent = $('#selectpickerimpact')[0].parentElement
            parent.id = "LMDLimpactPicker"

        });
    }

    function setAuthors(data) {
        let authorsArray = data.aggregations.authors.buckets
        let authorsList = []
        authorsArray.forEach(element => {
            allAuthors.push(element.key)
            authorsList.push("<option>" + element.key + "</option>")
        });
        let selectObjects = document.getElementById("selectpickerauthor")
        selectObjects.innerHTML = authorsList.join("")
        afterSearchQuery.query.bool.must[0].bool.filter[1].terms["author.keyword"] = allAuthors
        $('#selectpickerauthor').selectpicker();
        $('#selectpickerauthor').on('changed.bs.select', function(e, clickedIndex, isSelected, previousValue) {
            if (isSelected) {
                authors.add(allAuthors[clickedIndex])
            } else {
                authors.delete(allAuthors[clickedIndex])
            }

            if (authors.size == 0) {
                afterSearchQuery.query.bool.must[0].bool.filter[1].terms["author.keyword"] = allAuthors
            } else {
                afterSearchQuery.query.bool.must[0].bool.filter[1].terms["author.keyword"] = Array.from(authors)
            }

            searchLMDP()
        }).on('loaded.bs.select', function(e) {
            let parent = $('#selectpickerauthor')[0].parentElement
            parent.id = "LMDLauthorPicker"
        });
        $("#selectpickerauthor").on("shown.bs.select", function() {
            $(document).off('keydown')
        });
        $('#selectpickerauthor').on('hidden.bs.select', function() {
            $(document).on('keydown', function(e) {
                if (e.key.length == 1 && !e.ctrlKey) {
                    if (!$("#search-modal").hasClass('show')) {
                        $("#search-modal").modal()
                    }
                }
            });
        });
    }

    $('#LMDLmoreFiltersButton').click(function() {
        if ($(this)[0].classList.contains('on')) {
            $('#LMDLcategoryPicker')[0].style.display = "none"
            $('#LMDLimpactPicker')[0].style.display = "none"
            $('#LMDLauthorPicker')[0].style.display = "none"
            $('.LMDLfiltersearch')[0].style.display = "none"
            $('.LMDLfilters')[0].style['justify-content'] = "space-around"
            $('.LMDLfilters')[0].style['align-items'] = "center"
            $(this)[0].classList.remove("on")
            $(this)[0].innerHTML = `<div class="notShown" id="LMDLmoreFiltersButton">More filters&nbsp;<i class="fas fa-caret-down" style="color: #555753;"></i></div>`
            $('.LMDLfilters')[0].style['flex-wrap'] = "initial"
        } else {
            $('#LMDLcategoryPicker')[0].style.display = "flex"
            $('#LMDLimpactPicker')[0].style.display = "flex"
            $('#LMDLauthorPicker')[0].style.display = "flex"
            $('.LMDLfiltersearch')[0].style.display = "flex"
            $('.LMDLfilters')[0].style['justify-content'] = "space-between"
            $('.LMDLfilters')[0].style['align-items'] = "normal"
            $('.LMDLfilters')[0].style['flex-wrap'] = "wrap"
            $(this)[0].classList.add("on")
            $(this)[0].innerHTML = `<div class="notShown" id="LMDLmoreFiltersButton">Less filters&nbsp;<i class="fas fa-caret-up" style="color: #555753;"></i></div>`
        }
    });

    function setMoreDetailsOnClick(id) {
        let moreButton = document.getElementById(id)
        moreButton.onclick = function() {
            let element = $(this)[0].childNodes[0]
            if (element.classList.contains('on')) {
                element.innerHTML = `Show more&nbsp;<i class=\"fas fa-angle-down LMDLmoreSmallDetailsI\"></i>`
                element.classList.remove("on");
                $(`#${id}header`)[0].style.display = "none"
                $(`#${id}detail`)[0].style.display = "none"
            } else {
                element.innerHTML = `Show less&nbsp;<i class=\"fas fa-angle-up LMDLmoreSmallDetailsI\"></i>`
                element.classList.add("on");
                $(`#${id}header`)[0].style.display = "table-row"
                $(`#${id}detail`)[0].style.display = "table-row"
            }
        };
    }

})();
