let allSearchCategory = ["Guide", "Reference", "Developer", "Other"]
let searchCategory = new Set([]);
let allImportance = ["Major", "Significant", "Minor"]
let importance = new Set([]);
let allSearchIn = ["Title", "Text", "Commit message"]
let searchIn = new Set([])
let authors = new Set([])
let allAuthors = []
var shouldIgnoreScroll = false;

// $('.ovalChange').click(function() {
//     $(this).toggleClass('on');
//     let name = this.id.replace('oval', '')
//     if (this.classList.contains('on')) {
//         document.getElementById("check" + name).className = 'fas fa-check'
//         this.innerHTML = this.innerHTML.replace(name.toUpperCase(), "&nbsp;" + name.toUpperCase())
//         console.log(this.innerHTML)
//         importance.add(name)
//     } else {
//         document.getElementById("check" + name).className = ''
//         this.innerHTML = this.innerHTML.replace("&nbsp;" + name.toUpperCase(), name.toUpperCase())
//         console.log(this.innerHTML + name.toUpperCase())
//         importance.delete(name)
//     }
//     afterSearchQuery.query.bool.must[0].bool.filter[0].terms["importance.keyword"] = Array.from(importance)
//     searchLMDP()
// });

// $('.ovalSearchIn').click(function() {
//     $(this).toggleClass('on');
//     let name = ""
//     if (this.id == "ovalText") {
//         searchText = !searchText
//         name = "text"
//     } else {
//         searchTitle = !searchTitle
//         name = "title"
//     }
//     if (this.classList.contains('on')) {
//         document.getElementById("check" + name).className = 'fas fa-check'
//         this.innerHTML = this.innerHTML.replace(name.toUpperCase(), "&nbsp;" + name.toUpperCase())
//         console.log(this.innerHTML)
//     } else {
//         document.getElementById("check" + name).className = ''
//         this.innerHTML = this.innerHTML.replace("&nbsp;" + name.toUpperCase(), name.toUpperCase())
//         console.log(this.innerHTML + name.toUpperCase())
//     }
//     searchLMDP()
// });

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

// let commitsFilterQuery = {
//     query: {
//         bool: {
//             filter: [{
//                 terms: {
//                     "importance.keyword": Array.from(importance)
//                 }
//             },{
//                 terms: {
//                     "author.keyword": Array.from(authors)
//                 }
//             }]
//         }
//     },
//     size: 0,
//     aggs: {
//         id: {
//             terms: {
//                 field: "docsID.keyword",
//                 size: 100000,
//                 order: {
//                     first_event_occur: "desc"
//                 }
//             },
//             aggs: {
//                 first_event_occur: {
//                     min: {
//                         field: "date"
//                     }
//                 }
//             }
//         }
//     }
// }

function OSrequest(method, url, query, async, callback) {
    $.ajax({
        method: method,
        url: url,
        crossDomain: true,
        // xhrFields: {
        //     withCredentials: true
        // },
        // headers: {
        //     "Authorization": "Basic " + btoa(username + ":" + password)
        // },
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
        // if (commitMessage == undefined) {
        //     commitMessage = data.hits.hits[i]._source.commitMessage
        // }

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
            // if (rawDate == undefined) {
            //     rawDate = data.hits.hits[i]._source.lastModificationDate
            // }
        const parsedDate = Date.parse(rawDate)
        const date = new Date(parsedDate)

        let upkeepStatus = data.hits.hits[i]._source["upkeep-status"]
        if (typeof upkeepStatus == 'undefined' || !upkeepStatus) {
            upkeepStatus = "unknown"
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
            contentTriangleClass = "fas fa-exclamation-triangle conditionTriangle"
        }

        let contentType = data.hits.hits[i]._source.contentType;
        // if (contentType == undefined) {
        //     contentType = data.hits.hits[i]._source.type
        // }

        impactOfChange = data.hits.hits[i]._source.importance

        let author = data.hits.hits[i]._source.author

        author = author.replace(/<.*>/, "")
            //changedContext = data.hits.hits[i]._source.changedContext

        listitems.push(`<tr>
        <th scope="row"><a href="https://github.com/Evolveum/docs/commits/master/${data.hits.hits[i]._source.gitUrl}">${title}</a><i data-toggle="tooltip" title="${contentStatus}" class="${contentTriangleClass}"></th>
        <td class="LMDLcategory${contentType} LMDLcategory">${contentType.toUpperCase()}</td>
        <td class="tableCentered LMDLimpact${impactOfChange} LMDLimpact">${impactOfChange.toUpperCase()}</td>
        <td class="tableCentered">${author}</td>
        <td class="tableCentered">${date.toLocaleDateString('en-GB', { timeZone: 'UTC' })}</td>
        <td class="tableCentered">${upkeepStatus}&nbsp;<i id="upkeep${upkeepStatus}" class="fa fa-circle LMDLupkeep${upkeepStatus}"></td>
        <td>${commitMessage}</td>
        </tr>`);
    }
    listbox.innerHTML += listitems.join("")
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

    let scrollEvent = function() {
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


    OSrequest("POST", "https://opensearch.lab.evolveum.com/docs_commits/_search", afterSearchQuery, true, updateList)
}

$(document).ready(function() {
    setLMDLSearchIn()
    setLMDLCategory()
    setLMDLImpact()

    $(".LMDLtooltipTh").tooltip()

    OSrequest("POST", "https://opensearch.lab.evolveum.com/docs_commits/_search", initialSearchQuery, true, updateList)

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

    OSrequest("POST", "https://opensearch.lab.evolveum.com/docs_commits/_search", request, true, setAuthors)

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

    });
}

// $('.ovalCategory').click(function() {
//     $(this).toggleClass('on');
//     let name = this.id.replace('ovalLMDL', '')
//     if (this.classList.contains('on')) {
//         document.getElementById("check" + name).className = 'fas fa-check'
//         this.innerHTML = this.innerHTML.replace(name.toUpperCase(), "&nbsp;" + name.toUpperCase())
//         console.log(this.innerHTML)
//         searchCategory.add(name)
//     } else {
//         document.getElementById("check" + name).className = ''
//         this.innerHTML = this.innerHTML.replace("&nbsp;" + name.toUpperCase(), name.toUpperCase())
//         console.log(this.innerHTML + name.toUpperCase())
//         searchCategory.delete(name)
//     }
//     afterSearchQuery.query.bool.must[0].bool.filter[2].terms["contentType.keyword"] = Array.from(searchCategory)
//     searchLMDP()
// });

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

// function firstFilter(beginningIndex = 0) {
//     afterSearchQuery.from = beginningIndex
//     if (authors.size == allAuthors.length && importance.size == 3) {
//         searchLMDP()
//     }
//     OSrequest("POST", "https://opensearch.lab.evolveum.com/docs_commits/_search", commitsFilterQuery, "search", "YvHY6hR8Zets+fGQ", true, filterByIds)
// }

// function filterByIds(data) {
//     let idArrays = data.aggregations.id.buckets

// }