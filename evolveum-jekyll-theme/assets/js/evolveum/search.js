---
---
(function() {

    // This is not entirely neccessary because we trust the content from our own search service,
    // but it is a last resort. Main problem may be community integration catalog.

    function escapeHtml(value) {
        return String(value ?? '').replace(/[&<>"']/g, char => ({
            '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
        })[char]);
    }

    function removeDoubleEncoding(escapedHtml) {
        return escapedHtml.replace(/&amp;((?:#\d+|#x[\da-f]+|[a-z][a-z\d]+);)/gi, '&$1');
    }

    function escapeSearchText(value) {
        return removeDoubleEncoding(escapeHtml(value));
    }

    function safeHighlight(value) {
        return removeDoubleEncoding(escapeHtml(value)
            .replaceAll('&lt;strong&gt;', '<strong>')
            .replaceAll('&lt;/strong&gt;', '</strong>'));
    }

    function safeUrl(value) {
        if (typeof value !== 'string' || !value.trim()) return null;
        try {
            const url = new URL(value, window.location.origin);
            return ['http:', 'https:'].includes(url.protocol) ? url.href : null;
        } catch {
            return null;
        }
    }


    {% if site.environment.name contains "docs" %}
    let letters = new Set(["Guide", "Book", "Reference", "Other", "Integrations"]);
    let branches = new Set([])

    $('#select-version-picker-search').on('changed.bs.select', function(e, clickedIndex, isSelected, previousValue) {
        let newVersion = $(this).find('option').eq(clickedIndex).text();
        let newVersionEdited = DOCSBRANCHMAP[newVersion]
        if (isSelected) {
            branches.add(newVersionEdited)
        } else {
            branches.delete(newVersionEdited)
        }
        if (branches.size == 0 && "branches" in searchQuery) {
            delete searchQuery.branches
        } else if (branches.size > 0) {
            searchQuery.branches = Array.from(branches)
        }
        searchForPhrase()
    });

    $('.ovalSearch').on('click', function() {
        const name = this.id.replace('oval', '');
        const selected = !letters.has(name);
        if (selected) {
            letters.add(name);
        } else {
            letters.delete(name);
        }
        $(this).toggleClass('on', selected).attr('aria-pressed', String(selected));
        $(this).find('i').toggleClass('fas fa-check', selected);
        searchForPhrase();
    });

    {% endif %}

    $('#docssearchbutton').on('click', function() {
        searchForPhrase();
    });

    var typingTimer = null;
    let activeSearchRequest = null;
    let searchRequestId = 0;
    let navigationItems = [];
    let navigationIndex = 0;

    function invalidateSearch() {
        searchRequestId++;
        if (activeSearchRequest) {
            activeSearchRequest.abort();
            activeSearchRequest = null;
        }
    }

    function clearSearchResults() {
        const suggestionBox = document.getElementById('autocombox');
        suggestionBox.innerHTML = '';
        suggestionBox.style.display = 'none';
        navigationItems = [];
        navigationIndex = 0;
    }

    function hasSearchText(query) {
        return Boolean(query.trim());
    }

    // Input covers typing, paste, mobile keyboards, and composition completion.
    $('#searchbar').on('input compositionend', function(event) {
        invalidateSearch();
        clearTimeout(typingTimer);
        typingTimer = null;
        $('[data-toggle="tooltip"]').tooltip('dispose');

        const query = $('#searchbar').val();
        if (!hasSearchText(query)) {
            clearSearchResults();
            return;
        }
        if (event.originalEvent?.isComposing) return;
        typingTimer = setTimeout(searchForPhrase, 200);
    });

    $(document).on('keydown', function(e) {
        if (e.target?.closest('input, textarea, select, [contenteditable]')) return;
        if (e.originalEvent?.isComposing) return;
        if (/^[a-zA-Z0-9-_ ]$/.test(e.key) && !e.altKey && !e.ctrlKey && !e.metaKey && e.which !== 32) {
            if (!$("#search-modal").hasClass('show')) {
                $("#search-modal").modal()
                clearTimeout(typingTimer);
                typingTimer = setTimeout(searchForPhrase, 200)
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

        $('#reportSearchProblemPopover').off('inserted.bs.popover.searchReport').on('inserted.bs.popover.searchReport', function() {
            $('#reportSearchProblemPopoverClose').click(function() {
                $('#reportSearchProblemPopover').popover('hide');
            });

            $('#searchReportAProblemSelect').selectpicker();

            $('#reportSearchProblemPopoverSend').click(function() {
                let searchProblemCategory = $("#searchReportAProblemSelect").val() || "Not defined"

                let details = $("#searchReportTextArea").val()
                if (details == undefined || details == "") {
                    details = "No details provided"
                }

                let reportSearchQuery = {
                    category: searchProblemCategory,
                    details: details,
                    query: document.getElementById('searchbar').value,
                    width: $(document).width(),
                    height: $(document).height()
                }
                OSrequest("POST", "https://{{ site.environment.docsUrl }}/webhooks/report/search", reportSearchQuery, true)
                $('#reportSearchProblemPopover').popover('hide');
            });
        })
    }

    $("#search-modal").on('hide.bs.modal', function() {
        invalidateSearch();
        clearTimeout(typingTimer);
        typingTimer = null;
        navigationItems = [];
        navigationIndex = 0;
    });

    $("#search-modal").on('hidden.bs.modal', function() {
        $('#reportSearchProblemPopover').popover('dispose');
        // Dispose all tooltips before clearing content
        $('[data-toggle="tooltip"]').tooltip('dispose');
        document.getElementById("autocombox").innerHTML = "";
        document.getElementById("autocombox").style.display = "none";
        document.getElementById('searchToggle').value = "";
        document.getElementById('searchbar').value = "";
    });

    function OSrequest(method,url, query, async, callback, errorCallback) {
        const headers = {};
        {% if site.environment.name contains "guide" %}
        const requestUrl = new URL(url, window.location.origin);
        const guidePaths = ['/api/v1/guide-search', '/api/v1/likes/guide', '/api/v1/likes/search/guide'];
        if (requestUrl.origin === 'https://{{ site.environment.searchUrl }}'
            && guidePaths.includes(requestUrl.pathname.replace(/\/$/, ''))) {
            headers['Authorization'] = 'Bearer ' + {{ site.environment.searchApiKey | jsonify }};
        }
        {% endif %}
        return $.ajax({
            headers: headers,
            method: method,
            url: url,
            crossDomain: true,
            async: async,
            data: JSON.stringify(query),
            dataType: 'json',
            contentType: 'application/json',
        }).done(function(data) {
            if (typeof callback !== 'undefined' && callback) {
                callback(data, false)
            }
        }).fail(function(data, status) {
            if (status !== 'abort') {
                console.log(data);
                if (typeof errorCallback === 'function') errorCallback();
            }
        });
    }

    // Object sent to search api service, not the actual opensearch query
    let searchQuery = {
        query: "query",
        {% if site.environment.name contains "docs" %}
        categories: Array.from(letters),
        {% endif %}
        type: "basic",
        size: 7
    }

    const catalogUrl = {{ site.environment.catalogUrl | default: "https://integrations.evolveum.com" | jsonify }};

    function makeAnchor(text) {
        if (!text) return '';
  
        let slug = text.toLowerCase().trim();
        
        slug = slug.normalize('NFD').replace(/[\u0300-\u036f]/g, '');
        
        slug = slug.replace(/[^a-z0-9\s-]/g, ' ').trim();
        
        slug = slug.replace(/[\s-]+/g, '-');
        
        return slug;
    }

    function searchForPhrase(pagesShown = 7) {

        $('[data-toggle="tooltip"]').tooltip('hide')

        invalidateSearch();
        const requestId = searchRequestId;
        clearTimeout(typingTimer);
        typingTimer = null;
        const actQuery = JSON.parse(JSON.stringify(searchQuery))

        let query = document.getElementById('searchbar').value
        if (!hasSearchText(query)) {
            clearSearchResults();
            return;
        }
        
        {% if site.environment.name contains "docs" %}
        actQuery.categories = Array.from(letters)
        actQuery.default_branch = DEFAULTDOCSBRANCH;
        {% endif %}

        actQuery.type = "basic";
        const searchType = actQuery.type;
        const headingQuery = query.trim().toLowerCase();

        actQuery.query = query
        actQuery.size = pagesShown;

        const showResults = function(data) {
            if (requestId !== searchRequestId) return;
            activeSearchRequest = null;
            console.log(data)
            const showItems = []
            let numberOfItems = data.total
            const suggestionBox = document.getElementById("autocombox")
            if (numberOfItems > 0) {

                if (numberOfItems === 1) {
                    showItems.push('<li class="notShown">' + numberOfItems + ' search result' + '</li>')
                } else {
                    showItems.push('<li class="notShown">' + numberOfItems + ' search results' + '</li>')
                }

                for (let i = 0; i < pagesShown && i < numberOfItems; i++) {
                    const fields = data.results[i].fields;
                    const isCatalog = data.results[i].source === "catalog";
                    let text = undefined
                    let title = undefined
                    {% if site.environment.name contains "docs" %}
                    let branch = data.results[i].fields.branch
                    let branchClass = "searchResultNotBranched"
                    let branchLabel = ""
                    let displayBranch = ""
                    let tooltipVer = "not versioned"

                    if (branch != null && branch != "notBranched") {
                        branchClass = "searchResultBranched"
                        displayBranch = DOCSBRANCHMAP[branch]
                        tooltipVer = displayBranch
                        const rawColor = DOCSBRANCHESCOLORS.get(displayBranch);
                        const colorString = /^#[0-9a-f]{6}$/i.test(rawColor) ? rawColor : 'inherit';
                        branchLabel = `<span id="branch${escapeHtml(branch)}" class="typeLabel branchLabel" style="color: ${colorString}; border-color: ${colorString};">${escapeHtml(displayBranch)}</span>`
                    } else {
                        branch = "notBranched"
                    }
                    {% endif %}

                    if (data.results[i].highlight != undefined) {
                        const highlight = data.results[i].highlight;
                        text = isCatalog
                            ? highlight.description ?? highlight["integrations.description"]
                                ?? highlight["integrations.connectors.description"]
                                ?? highlight["integrations.name"] ?? highlight["integrations.connectors.name"]
                            : highlight.text;
                        title = isCatalog ? highlight.name : highlight.title;
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
                        preview = isCatalog
                            ? (fields.description?.[0] ?? '').slice(0, 240)
                            : fields.alternative_text?.[0] ?? ''
                    }

                    preview = safeHighlight(preview);

                    let cleanTitle = "" // Title without highlighting used for setSearchItemOnclick

                    if (isCatalog) {
                        cleanTitle = fields.name?.[0] ?? "Integration application";
                    } else if (data.results[i].fields.title != undefined) {
                        cleanTitle = data.results[i].fields.title[0]
                    } else if (data.results[i].fields.second_titles != undefined) {
                        cleanTitle = data.results[i].fields.second_titles[0]
                    } else {
                        cleanTitle = "Not defined"
                    }

                    if (title == undefined || !title) {
                        title = escapeSearchText(cleanTitle);
                    } else {
                        title = safeHighlight(title);
                    }

                    setTimeout(function() {
                        if (requestId !== searchRequestId) return;
                        setSearchItemOnclick(data.results[i].id, cleanTitle, i, query, searchType, pagesShown, data.results[i].source);
                    }, 130);

                    let displayDate = "Not defined"

                    const modifiedDate = isCatalog ? fields.updated?.[0] : fields.lastModificationDate?.[0];
                    if (modifiedDate != undefined) {
                        const parsedDate = Date.parse(modifiedDate)
                        const date = new Date(parsedDate)
                        displayDate = date.toLocaleDateString('en-GB', { timeZone: 'UTC' })
                    }

                    let authorRaw = data.results[i].fields.author
                    let author = ""
                    if (typeof authorRaw == 'undefined' || !authorRaw) {
                        authorRaw = data.results[i].fields["wiki-metadata-create-user"]
                        author = "unknown"
                        if (typeof authorRaw != 'undefined' && authorRaw) {
                            author = authorRaw[0]
                        }
                    } else {
                        author = authorRaw[0]
                    }

                    let searchUpvotesRaw = data.results[i].fields.upvotes
                    let searchUpvotes = 0
                    if (typeof searchUpvotesRaw != 'undefined' && searchUpvotesRaw) {
                        searchUpvotes = searchUpvotesRaw[0]
                    }

                    let docsUpvotesRaw = data.results[i].fields.docslikes
                    let docsUpvotes = 0
                    if (typeof docsUpvotesRaw != 'undefined' && docsUpvotesRaw) {
                        docsUpvotes = docsUpvotesRaw[0]
                    }

                    let upkeepStatusRaw = data.results[i].fields["upkeep-status"]
                    let upkeepStatus = "unknown"
                    if (typeof upkeepStatusRaw != 'undefined' && upkeepStatusRaw) {
                        upkeepStatus = upkeepStatusRaw[0]
                    }
                    const upkeepColor = ["orange", "red", "green", "yellow"].includes(upkeepStatus)
                        ? upkeepStatus : "unknown";

                    contentTriangleClass = "fas fa-exclamation-triangle conditionTriangle"
                    contentStatusArray = [data.results[i].fields.obsolete, data.results[i].fields.deprecated, data.results[i].fields.experimental, data.results[i].fields.planned, data.results[i].fields.outdated]
                    contentStatusValuesArray = ["obsolete", "deprecated", "experimental", "planned", "outdated"]
                    contentStatus = "" // TODO as array
                    filtredArray = contentStatusArray.filter(function(element, index) {
                        if (element != undefined && element == "true") {
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

                    let pageUrl = isCatalog
                        ? safeUrl(catalogUrl.replace(/\/+$/, '') + '/applications/' + encodeURIComponent(data.results[i].id))
                        : safeUrl(fields.url?.[0]);

                    {% if site.environment.name contains "docs" %}
                    let typeRaw = data.results[i].fields.type
                    let type = isCatalog ? "Integrations" : "other"
                    if (!isCatalog && typeRaw != undefined && typeRaw) {
                        type = typeRaw[0]
                    }
                    {% endif %}
                    
                    const cleanTitleLower = cleanTitle.toLowerCase()
                    if (!isCatalog && headingQuery && !cleanTitleLower.includes(headingQuery)) {
                        let titleArr = data.results[i].fields.second_titles != undefined ? data.results[i].fields.second_titles : []
                        if (data.results[i].fields.third_titles != undefined) {
                            titleArr = titleArr.concat(data.results[i].fields.third_titles)
                        }
                        if (data.results[i].fields.fourth_titles != undefined) {
                            titleArr = titleArr.concat(data.results[i].fields.fourth_titles)
                        }
                        for (const titleOption of titleArr) {
                            if (typeof titleOption != 'undefined' && titleOption.toLowerCase().includes(headingQuery)) {
                                if (pageUrl) pageUrl = pageUrl + "#" + makeAnchor(titleOption)
                                break;
                            }
                        }
                    }
                    const tooltip = isCatalog
                        ? `<span class="tooltip-preview"><p>Integration application</p><p>Last modification date: ${escapeHtml(displayDate)}</p><p>Search likes: ${escapeHtml(searchUpvotes)}</p></span>`
                        : `<span class="tooltip-preview"><p>Last modification date: ${escapeHtml(displayDate)}</p>
                    <p>Upkeep status: ${escapeHtml(upkeepStatus)} <i class="fa fa-circle upkeep-${upkeepColor}"></i>
                    </p><p>Search likes: ${escapeHtml(searchUpvotes)}</p><p>Docs likes: ${escapeHtml(docsUpvotes)}</p>{% if site.environment.name contains "docs" %}<p>Version: ${escapeHtml(tooltipVer)}</p>{% endif %}<p>Author: ${escapeHtml(author)}</p><p>Content: ${escapeHtml(contentStatus)} <i class="${contentTriangleClass}" style="margin-left: 5px;"></i></p></span>`;
                    // Escape again for the attribute: Bootstrap later parses the tooltip HTML.
                    const linkAttribute = pageUrl ? `href="${escapeHtml(pageUrl)}"` : 'aria-disabled="true"';
                    const vote = `<span class="vote" id="${escapeHtml(data.results[i].id)}up"><i class="fas fa-thumbs-up"></i></span>`;
                    showItems.push(`<div><span class="trigger-details searchResult" data-toggle="tooltip" data-placement="left"
                    data-html="true" title="${escapeHtml(tooltip)}"><a class="aWithoutUnderline" ${linkAttribute}
                    id="${escapeHtml(data.results[i].id)}site"><li class="list-group-item border-0 search-list-item"><i class="fas fa-align-left"></i>
                    <span class="font1 searchResultTitle {% if site.environment.name contains "docs" %}${branchClass}{% endif %}">&nbsp;${title}</span>{% if site.environment.name contains "docs" %}<span id="label${escapeHtml(type)}" class="typeLabel">${escapeHtml(String(type).toUpperCase())}</span>${branchLabel}{% endif %}<i class="${contentTriangleClass}"></i><br><span class="font2">${preview}</span></li></a></span>
                    ${vote}</div>`);
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
                    {% if site.environment.name contains "docs" %}
                    moreClick = {
                        "search_query": query,
                        "num_results": pagesShown + 7,
                        "categories": Array.from(letters),
                        "type": searchType
                    }
                    if (branches.size > 0) {
                        moreClick.branches = Array.from(branches)
                    } else {
                        moreClick.default_branch = DEFAULTDOCSBRANCH
                    }
                    OSrequest("POST", "https://{{ site.environment.searchUrl }}/api/v1/logs/more_results", moreClick, false)
                    {% endif %}
                    searchForPhrase(pagesShown + 7)
                });

            } else {
                suggestionBox.innerHTML = '<li class="notShown" role="status">No results found.</li>';
                suggestionBox.style.display = 'table';
            }

            $('[data-toggle="tooltip"]').tooltip({
                trigger: 'hover',
                delay: { show: 100, hide: 100 }
            });

            setHighlighting();

        }

        const showError = function() {
            if (requestId !== searchRequestId) return;
            activeSearchRequest = null;
            clearSearchResults();
            const suggestionBox = document.getElementById('autocombox');
            suggestionBox.innerHTML = '<li class="notShown" role="alert">Search is currently unavailable. Please try again.</li>';
            suggestionBox.style.display = 'table';
        };

        activeSearchRequest = OSrequest("POST", "https://{{ site.environment.searchUrl }}/api/v1/{% if site.environment.name contains "docs" %}search{% else %}guide-search{% endif %}", actQuery, true, showResults, showError)
    }

    function setHighlighting() {
        navigationItems = Array.from(document.querySelectorAll('#search-modal #searchbar, #search-modal .aWithoutUnderline'));
        navigationIndex = 0;
        for (const item of navigationItems) {
            item.classList.remove('highlightSearch');
            if (item.id !== 'searchbar') {
                item.parentElement.parentElement.classList.remove('highlightParentSearch');
            }
        }
        if (navigationItems.length) {
            navigationItems[0].classList.add('highlightSearch');
        }
    }

    $(document).on('keydown.searchNavigation', function(event) {
        if (!$('#search-modal').hasClass('show') || !navigationItems.length) return;
        if (event.keyCode !== 38 && event.keyCode !== 40) return;
        if (!navigationItems.includes(document.activeElement)) return;

        event.preventDefault();
        navigationIndex = navigationItems.indexOf(document.activeElement);
        const previous = navigationItems[navigationIndex];
        previous.classList.remove('highlightSearch');
        if (previous.id !== 'searchbar') {
            previous.parentElement.parentElement.classList.remove('highlightParentSearch');
        }

        const direction = event.keyCode === 38 ? -1 : 1;
        navigationIndex = Math.max(0, Math.min(navigationItems.length - 1, navigationIndex + direction));
        const current = navigationItems[navigationIndex];
        current.classList.add('highlightSearch');
        if (current.id !== 'searchbar') {
            current.parentElement.parentElement.classList.add('highlightParentSearch');
        }
        current.focus({ focusVisible: true });
    });

    function setSearchItemOnclick(id, title, position, query, searchType, pagesShown, source) {

        let up = document.getElementById(id + "up")
        if (up) up.onclick = function() {
            let modify = true

            if ($(this).prop("classList").contains('on')) {
                modify = false
            }

            const queryUpvote = {
                {% if site.environment.name contains "docs" %}
                "result_source": source === "catalog" ? "catalog" : "docs",
                "type": searchType,
                "search_query": query,
                "position": position,
                "title": title,
                "num_results": pagesShown,
                {% endif %}
                "id": id,
                "like": modify
            }

            {% if site.environment.name contains "docs" %}
            if (branches.size > 0) {
                queryUpvote.branches = Array.from(branches)
            } else {
                queryUpvote.default_branch = DEFAULTDOCSBRANCH
            }
            queryUpvote.categories = Array.from(letters)
            {% endif %}

            OSrequest("POST", "https://{{ site.environment.searchUrl }}/api/v1/likes/search/{% if site.environment.name contains "docs" %}docs{% else %}guide{% endif %}", queryUpvote, true)

            $(this).toggleClass('on');
        };

        {% if site.environment.name contains "docs" %}
        const site = document.getElementById(id + "site");

        const recordActivation = function() {
            // Disabled/invalid links do not navigate and should not count as clicks.
            if (!site.hasAttribute('href')) return;
            $(site).parent().tooltip('hide');
            $('[data-toggle="tooltip"]').tooltip('hide');

            const queryClick = {
                "categories": Array.from(letters),
                "type": searchType,
                "search_query": query,
                "position": position,
                "title": title,
                "num_results": pagesShown,
                "result_id": id,
                "result_source": source,
                "result_url": site.href,
            };
            if (branches.size > 0) {
                queryClick.branches = Array.from(branches);
            } else {
                queryClick.default_branch = DEFAULTDOCSBRANCH;
            }

            // Keep logging alive when keyboard or primary-click navigation unloads the page.
            fetch("https://{{ site.environment.searchUrl }}/api/v1/logs/clicks", {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(queryClick),
                keepalive: true,
            }).catch(function(error) {
                console.log(error);
            });
        };

        site.addEventListener('click', function(event) {
            if (event.button === 0) recordActivation();
        });
        site.addEventListener('auxclick', function(event) {
            if (event.button === 1) recordActivation();
        });

        site.addEventListener("contextmenu", (event) => {
            // This isn't a perfect solution, right click may be anything other than open in new tab, but I think
            // it is better to have false positives than false negatives.
            recordActivation();
        });
        {% endif %}
    }

})();
