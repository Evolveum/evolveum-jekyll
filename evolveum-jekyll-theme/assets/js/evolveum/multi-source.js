/*
 * This script finds groups of code snippets in different languages and turns them into navbars.
 *
 * Groups must fulfill these requirements:
 *      1. Must have more than 1 code snippet.
 *      2. Code snippets must be in divisions with class name "listingblock" (and with specific DOM structure - please see the code).
 *      3. Code snippets must not have other DOM elements between them (except .colist callout lists).
 *      4. Code snippets must be written in different languages.
 *
 * It works like this:
 *
 * This script finds all elements of name "listingsblock". Then it determines if they will be replaced by navbar.
 * If element does not meet some demands, active group will end and if it meet some requirements, it will be replaced with navbar.
 * Arrays will be then reset and script will be finding new group.
 */

var groups = document.getElementsByClassName("listingblock");
var languageNames = []; // Contains names of languages of actual listings.
var codeSnippets = []; // Contains HTML divisions of actual listings (listingblock + optional colist).
var colistHTML = []; // Contains the outerHTML string of callout lists (captured before hiding).
var repeatedLanguage = false; // True if some language is more than once in a group.

const CONTENT_CLASS = "content";
const CODE_HIGHLIGHTER_CLASS = "rouge highlight";
const CODE_CLASS = "code";
const COLIST_CLASS = "colist";

// Extract language from a listingblock element
function getLanguage(el) {
    var div = el.getElementsByClassName(CONTENT_CLASS);
    var pre = div[0].getElementsByClassName(CODE_HIGHLIGHTER_CLASS);
    var code = pre[0].getElementsByTagName(CODE_CLASS);
    return code[0].getAttribute('data-lang');
}

// Get the colist (callout list) immediately following a listingblock, if any
function getNextColist(el) {
    var next = $(el).next();
    if (next.length > 0 && next[0].classList.contains(COLIST_CLASS)) {
        return next[0];
    }
    return null;
}

// Find the next .listingblock sibling, returning null if there are non-colist elements between
function getNextListingBlock(el) {
    var nextAll = $(el).nextAll();
    for (var i = 0; i < nextAll.length; i++) {
        var sibling = nextAll[i];
        if (sibling.classList.contains(COLIST_CLASS)) {
            continue; // Skip callout lists - they belong to the current code block
        }
        if (sibling.classList.contains("listingblock")) {
            return sibling;
        }
        // Any other element breaks the consecutive group
        return null;
    }
    return null;
}

for (var i = 0; i < groups.length; i++) {
    try {
        var lang = getLanguage(groups[i]);

        codeSnippets.push(groups[i]);
        languageNames.push(lang);

        var colistEl = getNextColist(groups[i]);
        // Store the outerHTML BEFORE we hide the element (avoiding inline style pollution)
        colistHTML.push(colistEl ? colistEl.outerHTML : null);

        // Find next listing block (skipping colists)
        var nextListingBlock = getNextListingBlock(groups[i]);

        if (nextListingBlock === null) {
            groupEnd();
        } else if (languageNames.includes(lang) && languageNames.lastIndexOf(lang) !== languageNames.length - 1) {
            repeatedLanguage = true;
        }

    } catch (e) {
        groupEnd();
        console.log(e.message);
    }
}

// Ends the group and reset arrays for another use. If group meets the requirements
// it will call showMenu and group will be replaced with navbar.
function groupEnd() {
    if (codeSnippets.length > 1 && !repeatedLanguage) {
        showMenu();
    }

    // Reset the data so main loop can use them on another group.
    repeatedLanguage = false;
    codeSnippets = [];
    languageNames = [];
    colistHTML = [];
}

// This function shows navigation bar based on arrays languages and code snippets.
// It runs through codeSnippets array and build navbar elements.
function showMenu() {
    var myGroupSnippet = document.createElement("div"); // Division where navbar will come.
    var reservedCodeSnippets = codeSnippets; // Saving code snippets to variable so script can use it when user click on navbar.
    var reservedColistHTML = colistHTML; // Saving callout HTML (captured before hiding)
    myGroupSnippet.className = "multilistingblock";

    var parent = codeSnippets[0].parentNode;
    parent.insertBefore(myGroupSnippet, codeSnippets[1]);

    var myUl = document.createElement("ul");
    myUl.className = "nav nav-tabs";
    myGroupSnippet.appendChild(myUl);

    var dLi = []; // Array of Li objects.
    var dA = []; // Array of A objects.

    for (var i = 0; i < codeSnippets.length; i++) {
        codeSnippets[i].style.display = 'none';
        // Hide the original colist element
        var colistEl = getNextColist(codeSnippets[i]);
        if (colistEl) {
            colistEl.style.display = 'none';
        }

        var LiO = document.createElement("li");
        LiO.className = "nav-item";

        myUl.appendChild(LiO);
        var AO = document.createElement("a");

        if (i == 0) {
            AO.className = "nav-link active";
        } else {
            AO.className = "nav-link";
        }

        AO.innerText = languageNames[i].toUpperCase();
        AO.style.cursor = "pointer";

        LiO.appendChild(AO);
        dLi.push(LiO);
        dA.push(AO);

    }
    let codeDiv = document.createElement("div");

    dA.forEach(function(currentValue, index) {
        currentValue.addEventListener('click', function() {

            let others = myUl.getElementsByClassName("nav-link active");
            for (let j in others) {
                others[j].className = "nav-link";
            }

            currentValue.className = "nav-link active";
            codeDiv.innerHTML = reservedCodeSnippets[index].innerHTML;
            // Append callout list HTML if it exists (clean copy without inline styles)
            if (reservedColistHTML[index]) {
                codeDiv.innerHTML += reservedColistHTML[index];
            }
        });
    });

    codeDiv.innerHTML = codeSnippets[0].innerHTML;
    // Show initial callout list if it exists (clean copy without inline styles)
    if (reservedColistHTML[0]) {
        codeDiv.innerHTML += reservedColistHTML[0];
    }
    myGroupSnippet.appendChild(codeDiv);
}
