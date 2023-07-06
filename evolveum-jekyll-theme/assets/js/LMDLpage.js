(function() {

    let allSearchCategory = ["Guide", "Reference", "Developer", "Other"]
    let searchCategory = new Set([]);
    let allImportance = ["Major", "Significant", "Minor"]
    let importance = new Set([]);
    let allSearchIn = ["Title", "Text", "Commit message"]
    let searchIn = new Set([])
    let authors = new Set([])
    let allAuthors = []
    var shouldIgnoreScroll = false;

    let initialSearchQuery = {
        query: {
            match_all: {}
        },
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

                ]
            }
        },
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
            let commitMessage = data.hits.hits[i]._source.commitMessage;
            let unknownStatus = "";

            if (commitMessage != undefined && commitMessage) {
                commitMessage = commitMessage.replaceAll("<", "&lt;")
                commitMessage = commitMessage.replaceAll(">", "&gt;")
            }

            let title = ""

            if (data.hits.hits[i].highlight == undefined) {
                title = data.hits.hits[i]._source.title
            } else {
                title = data.hits.hits[i].highlight.title
            }

            let rawDate = data.hits.hits[i]._source.date
            const parsedDate = Date.parse(rawDate)
            const date = new Date(parsedDate)

            let upkeepStatus = data.hits.hits[i]._source["upkeep-status"]
            if (typeof upkeepStatus == 'undefined' || !upkeepStatus) {
                upkeepStatus = "unknown"
                unknownStatus = "&nbsp;unknown"
            }

            contentTriangleClass = ""
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

            if (contentStatus != "") {
                contentTriangleClass = "fas fa-exclamation-triangle conditionTriangle LMDLelementTooltip"
            }

            let contentType = data.hits.hits[i]._source.contentType;

            impactOfChange = data.hits.hits[i]._source.importance

            let author = data.hits.hits[i]._source.author

            author = author.replace(/<.*>/, "")

            listitems.push(`<tr>
        <th class="LMDLtitle" scope="row"><a href="${data.hits.hits[i]._source.url}" class="LMDLelementTooltip" data-toggle="tooltip" data-html="true" data-original-title='<span>Upkeep status:&nbsp;<i id="upkeep${upkeepStatus}" class="fa fa-circle LMDLupkeep${upkeepStatus}"></i>${unknownStatus}</span>'>${title}</a>&nbsp;<a class="LMDLtitleGithubLink" href="https://github.com/Evolveum/docs/commits/master/${data.hits.hits[i]._source.gitUrl}">history&nbsp;<i class="fab fa-github"></i></a><i data-toggle="tooltip" title="${contentStatus}" class="${contentTriangleClass}"></th>
        <td class="LMDLcategory${contentType} LMDLcategory">${contentType.toUpperCase()}</td>
        <td class="tableCentered LMDLimpact${impactOfChange} LMDLimpact">${impactOfChange.toUpperCase()}</td>
        <td class="tableCentered LMDLauthor">${author}</td>
        <td class="tableCentered LMDLdate">${date.toLocaleDateString('en-GB', { timeZone: 'UTC' })}</td>
        <td class="LMDLmessage">${commitMessage}</td></tr>
        <tr id="${data.hits.hits[i]._source.id}header" class="LMDLexpandedHeader"><td scope="row" class="tableCentered LMDLexpandedHeader LMDLexpandedCategory">Category</td>
        <td scope="row" class="tableCentered LMDLtooltipTh LMDLexpandedHeader LMDLexpandedImpactHeader" data-toggle="tooltip" data-html="true" 
        title="<div><span>Extend to which the page had been modified</span><br><span><span class=&quot;LMDLimpactMajor&quot;>Major</span> - more than 30% of lines were edited</span><br><span><span class=&quot;LMDLimpactSignificant&quot;>Significant</span> - more than 10% and less than 30% of lines were edited</span><br><span><span class=&quot;LMDLimpactMinor&quot;>Minor</span> - less than 10% of lines were edited</span></div>">Impact of change&nbsp;<i style="font-size: 0.8rem;" class="fas fa-question-circle"></i></td>
        <td scope="row" class="tableCentered LMDLexpandedHeader LMDLexpandedAuthor">Author</td></tr>
        <tr id="${data.hits.hits[i]._source.id}detail" class="LMDLexpandedDetail"><td scope="row" class="LMDLcategoryGuide LMDLcategory">GUIDE</td>
        <td class="tableCentered LMDLimpactMinor LMDLimpact">MINOR</td>
        <td class="tableCentered LMDLauthor LMDLexpandedDetail">Jan Mederly</td></tr>
        <tr id="${data.hits.hits[i]._source.id}" class='LMDLmoreSmallDetails'><td colspan="3" class="notShown LMDLmoreSmallDetailsTd">Show more&nbsp;<i class="fas fa-angle-down LMDLmoreSmallDetailsI"></i></td></tr>`);
            setTimeout(setMoreDetailsOnClick(data.hits.hits[i]._source.id.toString()), 70);
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



        OSrequest("POST", "https://searchtest.evolveum.com/docs_commits/_search", afterSearchQuery, true, updateList)
    }

    $(document).ready(function() {
        setLMDLSearchIn()
        setLMDLCategory()
        setLMDLImpact()

        $("#LMDLsearchButton").click(function() {
            searchLMDP();
        });

        $(".LMDLtooltipTh").tooltip()

        OSrequest("POST", "https://searchtest.evolveum.com/docs_commits/_search", initialSearchQuery, true, updateList)

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

        OSrequest("POST", "https://searchtest.evolveum.com/docs_commits/_search", request, true, setAuthors)

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
        $('#LMDLcategoryPicker')[0].style.display = "initial"
        $('#LMDLimpactPicker')[0].style.display = "initial"
        $('#LMDLauthorPicker')[0].style.display = "initial"
        $('.LMDLfiltersearch')[0].style.display = "initial"
        $('.LMDLfilters')[0].style['justify-content'] = "space-between"
        $('.LMDLfilters')[0].style['align-items'] = "normal"
    });

    function setMoreDetailsOnClick(id) {
        $(`#${id}`).click(function() {
            let element = $(this)[0].childNodes[0]
            console.log(element + "somtu")
            if (element.prop("classList").contains('on')) {
                element.innerHTML = `Show more&nbsp;<i class=\"fas fa-angle-down LMDLmoreSmallDetailsI\"></i>`
                element.classList.remove("on");
                $(`#${id}header`)[0].style.display = "none"
                $(`#${id}detail`)[0].style.display = "none"
            } else {
                element.innerHTML = `Show less&nbsp;<i class=\"fas fa-angle-up LMDLmoreSmallDetailsI\"></i>`
                element.classList.add("on");
                $(`#${id}header`)[0].style.display = "table-row !important"
                $(`#${id}detail`)[0].style.display = "table-row !important"
            }
        });
    }

})();