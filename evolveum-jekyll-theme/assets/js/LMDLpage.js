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
    const endpoint = "https://{{ site.environment.searchUrl }}/api/v1/commits/{% if site.environment.name contains "docs" %}docs{% else %}guide{% endif %}";
    let dateRange = {};
    let activeRequest = null;
    let requestGeneration = 0;
    let nextOffset = 0;
    let hasMore = true;
    let rowNumber = 0;
    let currentQuery = {};

    // This is not entirely neccessary because we trust the content from our own search service,
    // but it is a last resort.

    function escapeHtml(value) {
        return String(value ?? '').replace(/[&<>"']/g, char => ({
            '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
        })[char]);
    }

    function safeUrl(value) {
        if (!value) return '#';
        try {
            const url = new URL(value, window.location.origin);
            return ['http:', 'https:'].includes(url.protocol) ? escapeHtml(url.href) : '#';
        } catch {
            return '#';
        }
    }

    function serviceRequest(method, url, query) {
        return $.ajax({
            method: method,
            url: url,
            {% if site.environment.name contains "guide" %}
            headers: { Authorization: 'Bearer ' + {{ site.environment.searchApiKey | jsonify }} },
            {% endif %}
            data: query === undefined ? undefined : JSON.stringify(query),
            dataType: 'json',
            contentType: 'application/json',
        });
    }

    function showError(message) {
        let error = document.getElementById('LMDLerror');
        if (!error) {
            error = document.createElement('p');
            error.id = 'LMDLerror';
            error.setAttribute('role', 'alert');
            const table = document.getElementById('listOfUpdatedPages').closest('table');
            table.parentNode.insertBefore(error, table);
        }
        error.textContent = message;
    }

    const updateList = function(data) {
        let listbox = document.getElementById("listOfUpdatedPages")
        let listitems = []
        const rowIds = [];
        for (let i = 0; i < data.results.length && i < data.total; i++) {
            const fields = Object.fromEntries(Object.entries(data.results[i].fields).map(([key, values]) => [
                key, (Array.isArray(values) ? values : [values]).map(value =>
                    key === 'url' || key === 'gitUrl' ? safeUrl(value) : escapeHtml(value))
            ]));
            for (const key of ['title', 'date', 'url', 'gitUrl']) {
                if (!fields[key] || !fields[key].length) fields[key] = [''];
            }
            const rowId = 'LMDLrow' + rowNumber++;
            rowIds.push(rowId);
            let commitMessageRaw = fields.commitMessage;
            let commitMessage = ""
            if (commitMessageRaw != undefined && commitMessageRaw) {
                commitMessage = commitMessageRaw[0]
            }
            let unknownStatus = "";

            {% if site.environment.name contains "docs" %}
            let contentVersion = "Not versioned"
            let contentDisplayVersion = "Not versioned"
            let versionColor = "#CACACA"

            if (fields.branch != undefined) {
                contentVersion = fields.branch[0]
                if (contentVersion != "Not versioned") {
                    let contentVersionWithoutDocs = contentVersion.replace("docs/", "")
                    contentDisplayVersion = DOCSBRANCHMAP[contentVersionWithoutDocs] || contentVersionWithoutDocs
                    versionColor = DOCSBRANCHESCOLORS.get(contentDisplayVersion) || "#CACACA"
                }
            }
            {% endif %}

            const title = fields.title[0];

            let rawDate = fields.date[0]
            const parsedDate = Date.parse(rawDate)
            const date = new Date(parsedDate)

            let upkeepStatusRaw = fields["upkeep-status"]
            let upkeepStatus = "unknown"
            if (typeof upkeepStatusRaw == 'undefined' || !upkeepStatusRaw) {
                unknownStatus = "&nbsp;unknown"
            } else {
                upkeepStatus = ["green", "yellow", "orange", "red"].includes(upkeepStatusRaw[0]) ? upkeepStatusRaw[0] : "unknown"
            }

            let contentTriangleClass = ""
            const contentStatusArray = [fields.obsolete, fields.deprecated, fields.experimental, fields.planned, fields.outdated]
            const contentStatusValuesArray = ["obsolete", "deprecated", "experimental", "planned", "outdated"]
            let contentStatus = ""
            contentStatusArray.forEach(function(element, index) {
                if (element != undefined && (element == "true")) {
                    contentStatus = contentStatusValuesArray[index]
                }
            });

            if (contentStatus != "") {
                contentTriangleClass = "fas fa-exclamation-triangle conditionTriangle LMDLelementTooltip"
            }

            let contentTypeRaw = fields.contentType;
            let contentType = ""
            if (typeof contentTypeRaw != 'undefined' && contentTypeRaw) {
                contentType = contentTypeRaw[0]
            }

            let impactOfChangeRaw = fields.importance
            let impactOfChange = ""
            if (typeof impactOfChangeRaw != 'undefined' && impactOfChangeRaw) {
                impactOfChange = impactOfChangeRaw[0]
            }

            let authorRaw = fields.author
            let author = ""
            if (typeof authorRaw != 'undefined' && authorRaw) {
                author = authorRaw[0]
            }

            author = author.replace(/&lt;.*?&gt;/g, "")


            listitems.push(`<tr>
        <th class="LMDLtitle" scope="row"><a href="${fields.url[0]}" class="LMDLelementTooltip" data-toggle="tooltip" data-html="true" data-original-title='<span>Upkeep status:&nbsp;<i id="upkeep${upkeepStatus}" class="fa fa-circle LMDLupkeep${upkeepStatus}"></i>${unknownStatus}</span>'>${title}</a>&nbsp;<a class="LMDLtitleGithubLink" href="${fields.gitUrl[0]}">history&nbsp;<i class="fab fa-github"></i></a><i data-toggle="tooltip" title="${contentStatus}" class="${contentTriangleClass}"></th>
        {% if site.environment.name contains "docs" %}<td class="LMDLcategory${contentVersion} LMDLcategory" style="color:${versionColor};">${contentDisplayVersion}</td>{% endif %}
        <td class="LMDLcategory${contentType} LMDLcategory">${contentType.toUpperCase()}</td>
        <td class="tableCentered LMDLimpact${impactOfChange} LMDLimpact">${impactOfChange.toUpperCase()}</td>
        <td class="tableCentered LMDLauthor">${author}</td>
        <td class="tableCentered LMDLdate">${Number.isNaN(parsedDate) ? '' : date.toLocaleDateString('en-GB', { timeZone: 'UTC' })}</td>
        <td class="LMDLmessage">${commitMessage}</td></tr>
        <tr id="${rowId}header" class="LMDLexpandedHeaderRow"><td scope="row" class="tableCentered LMDLexpandedHeader LMDLexpandedCategory">Category</td>
        <td scope="row" class="tableCentered LMDLtooltipTh LMDLexpandedHeader LMDLexpandedImpactHeader" data-toggle="tooltip" data-html="true" 
        title="<div><span>Extend to which the page had been modified</span><br><span><span class=&quot;LMDLimpactMajor&quot;>Major</span> - more than 30% of lines were edited</span><br><span><span class=&quot;LMDLimpactSignificant&quot;>Significant</span> - more than 10% and less than 30% of lines were edited</span><br><span><span class=&quot;LMDLimpactMinor&quot;>Minor</span> - less than 10% of lines were edited</span></div>">Impact of change&nbsp;<i style="font-size: 0.8rem;" class="fas fa-question-circle"></i></td>
        <td scope="row" class="tableCentered LMDLexpandedHeader LMDLexpandedAuthor">Author</td></tr>
        <tr id="${rowId}detail" class="LMDLexpandedDetailRow"><td scope="row" class="LMDLcategory${contentType} LMDLcategory LMDLexpandedDetail LMDLexpandedCategoryCell">${contentType.toUpperCase()}</td>
        <td class="tableCentered LMDLimpact${impactOfChange} LMDLimpact LMDLexpandedDetail LMDLexpandedImpactCell">${impactOfChange.toUpperCase()}</td>
        <td class="tableCentered LMDLauthor LMDLexpandedDetail LMDLexpandedAuthorCell">${author}</td></tr>
        <tr id="${rowId}" class='LMDLmoreSmallDetails'><td colspan="3" class="notShown LMDLmoreSmallDetailsTd">Show more&nbsp;<i class="fas fa-angle-down LMDLmoreSmallDetailsI"></i></td></tr>`);
        }
        listbox.insertAdjacentHTML("beforeend", listitems.join(""));
        rowIds.forEach(setMoreDetailsOnClick);
        $(".LMDLelementTooltip").tooltip();
    }

    function searchLMDP(append = false) {
        if (append && (activeRequest || !hasMore)) return;
        if (!append) {
            requestGeneration++;
            if (activeRequest) activeRequest.abort();
            nextOffset = 0;
            hasMore = true;
            document.getElementById('listOfUpdatedPages').innerHTML = '';
            const fieldNames = { Title: 'title', Text: 'text', 'Commit message': 'commitMessage' };
            currentQuery = {
                query: document.getElementById('LMDLsearchbar').value.trim(),
                search_in: Array.from(searchIn, field => fieldNames[field]),
                categories: Array.from(searchCategory),
                importance: Array.from(importance),
                authors: Array.from(authors),
                {% if site.environment.name contains "docs" %}
                branches: Array.from(filterBranches),
                {% endif %}
                ...dateRange,
            };
        }
        const generation = requestGeneration;
        showError('');
        const request = serviceRequest('POST', endpoint, { ...currentQuery, offset: nextOffset, size: 30 });
        activeRequest = request;
        request.done(function(data) {
            if (generation !== requestGeneration) return;
            updateList(data);
            nextOffset += data.results.length;
            hasMore = data.results.length > 0 && nextOffset < data.total && nextOffset <= 9970;
            if (!append && !data.total) showError('No changes match these filters.');
        }).fail(function(xhr, status) {
            if (generation !== requestGeneration || status === 'abort') return;
            showError('Unable to load changes. Please try again.');
        }).always(function() {
            if (generation === requestGeneration) activeRequest = null;
        });
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

        searchLMDP();
        serviceRequest('GET', endpoint + '/authors').done(setAuthors).fail(function() {
            showError('Unable to load the author filter. Please reload to try again.');
        });
        $(window).on('scroll.LMDL', function() {
            if ($(window).scrollTop() >= $(document).height() - $(window).height() - 10) {
                searchLMDP(true);
            }
        });
        $('#LMDLsearchbar').on('keydown', function(event) {
            if (event.key === 'Enter') {
                event.preventDefault();
                searchLMDP();
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
            dateRange = {
                date_from: picker.startDate.format('YYYY-MM-DD'),
                date_to: picker.endDate.format('YYYY-MM-DD'),
            };
            searchLMDP()
        });

        $('.LMDLDatePickerButton').on('cancel.daterangepicker', function(ev, picker) {
            document.getElementById("LMDLPickedDate").innerHTML = 'Pick a date range'
            document.getElementById("LMDLPickedDate").style.color = "#909090"
            dateRange = {};
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

    function updateSelection(select, selected, values) {
        selected.clear();
        Array.from(select.options).forEach((option, index) => {
            if (option.selected && values[index] !== undefined) selected.add(values[index]);
        });
    }

    function setLMDLSearchIn() {
        $('#selectpickersearchin').selectpicker();
        $('#selectpickersearchin').selectpicker('deselectAll');
        $('#selectpickersearchin').on('changed.bs.select', function() {
            updateSelection(this, searchIn, allSearchIn);
        });
    }

    {% if site.environment.name contains "docs" %}
    function setLMDLVersion() {
        let branchList = []
        for (let i = 0; i < DOCSBRANCHESDISPLAYNAMES.length; i++) {
            branchList.push("<option style=\"color: " + DOCSBRANCHESCOLORS.get(DOCSBRANCHESDISPLAYNAMES[i]) + ";\">" + DOCSBRANCHESDISPLAYNAMES[i] + "</option>")
        }
        let selectObjects = document.getElementById("selectpickerversion")
        selectObjects.innerHTML = branchList.join("")
        $('#selectpickerversion').selectpicker();
        $('#selectpickerversion').selectpicker('deselectAll');
        $('#selectpickerversion').on('changed.bs.select', function() {
            updateSelection(this, filterBranches, DOCSBRANCHESDISPLAYNAMES.map(name => DOCSBRANCHMAP[name]));

            searchLMDP()
        }).on('loaded.bs.select', function(e) {
            let parent = $('#selectpickerversion')[0].parentElement
            parent.id = "LMDLversionPicker"
        });
    }{% endif %}

    function setLMDLCategory() {
        $('#selectpickercategory').selectpicker();
        $('#selectpickercategory').selectpicker('deselectAll');
        $('#selectpickercategory').on('changed.bs.select', function() {
            updateSelection(this, searchCategory, allSearchCategory);

            searchLMDP()
        }).on('loaded.bs.select', function(e) {
            let parent = $('#selectpickercategory')[0].parentElement
            parent.id = "LMDLcategoryPicker"
        });
    }

    function setLMDLImpact() {
        $('#selectpickerimpact').selectpicker();
        $('#selectpickerimpact').selectpicker('deselectAll');
        $('#selectpickerimpact').on('changed.bs.select', function() {
            updateSelection(this, importance, allImportance);

            searchLMDP()
        }).on('loaded.bs.select', function(e) {

            // save the element
            let el = $(this);


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
        let authorsArray = data.authors
        let authorsList = []
        authorsArray.forEach(element => {
            allAuthors.push(element)
            authorsList.push("<option>" + escapeHtml(element) + "</option>")
        });
        let selectObjects = document.getElementById("selectpickerauthor")
        selectObjects.innerHTML = authorsList.join("")
        $('#selectpickerauthor').selectpicker();
        $('#selectpickerauthor').on('changed.bs.select', function() {
            updateSelection(this, authors, allAuthors);

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
                document.getElementById(id + "header").style.display = "none"
                document.getElementById(id + "detail").style.display = "none"
            } else {
                element.innerHTML = `Show less&nbsp;<i class=\"fas fa-angle-up LMDLmoreSmallDetailsI\"></i>`
                element.classList.add("on");
                document.getElementById(id + "header").style.display = "table-row"
                document.getElementById(id + "detail").style.display = "table-row"
            }
        };
    }

})();
