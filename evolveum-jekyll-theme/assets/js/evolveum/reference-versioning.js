var DOCSBRANCHESCOLORS = new Map();
var DOCSBRANCHDISPLAYNAMES = {
    master: "Development",
    Development: "master",
    "docs/before-4.8": "4.7 and earlier",
    "4.7 and earlier": "docs/before-4.8",
    "support-4.8": "4.8",
    "4.8": "support-4.8"
}

function decToHex(dec) {
    return dec.toString(16);
}

function padToTwo(str) {
    return str.padStart(2, '0');
}

function rgbToHex(r, g, b) {
    const hexR = padToTwo(decToHex(r));
    const hexG = padToTwo(decToHex(g));
    const hexB = padToTwo(decToHex(b));

    return `#${hexR}${hexG}${hexB}`;
}

window.addEventListener('load', function() {
    console.log($("#select-version-picker-search"))
    let options = document.getElementById('select-version-picker-search').options
    console.log("opts" + options)
    let start = 85
    let end = 210
    console.log(options.length)
    let step = Math.round((end - start) / options.length)
    console.log("ADB" + options)
    for (let o = 0; o < options.length; o++) {
        console.log(start + (o*step))
        console.log(o)
        console.log(options[o].tokens)
        DOCSBRANCHESCOLORS.set(options[o].value, rgbToHex(start + (o*step),start + (o*step),start + (o*step) + 35))
    }
    let url = window.location.href
    let urlSubstrings = url.split("/")
    let version = ""
    if (urlSubstrings.length > 6) {
        version = DOCSBRANCHDISPLAYNAMES[urlSubstrings[5].toString()]
    }

    if (!url.includes("/midpoint/reference")) {
        $("#select-version").css("display", "none");
    } else {
        $('#select-version-picker').selectpicker('val', version);
    }

    $('#select-version-picker').on('changed.bs.select', function(e, clickedIndex, isSelected, previousValue) {
        let newVersion = $(this).find('option').eq(clickedIndex).text();
        let newVersionEdited = DOCSBRANCHDISPLAYNAMES[newVersion].toString()
        console.log(newVersionEdited)
        console.log(url)
        console.log(urlSubstrings[5])
        redirectToAnotherVersion(urlSubstrings[5], newVersionEdited, url)
    });
});

function redirectToAnotherVersion(first, second, url) {
    window.location = url.replace(first, second)
}