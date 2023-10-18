var DOCSBRANCHESCOLORS = new Map();
var DOCSBRANCHDISPLAYNAMES = {
    "master": "Development",
    "Development": "master",
    "docsFWDSbefore-4.8": "4.7 and earlier",
    "4.7 and earlier": "docsFWDSbefore-4.8",
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
        console.log(options[o]['data-tokens'])
        console.log(options[o])
        DOCSBRANCHESCOLORS.set(options[o].value, rgbToHex(start + (o*step),start + (o*step),start + (o*step) + 35))
    }
    let url = window.location.href
    let urlSubstrings = url.split("/")
    let version = ""
    let versionDisplay = ""
    if (urlSubstrings.length > 6) {
        version = urlSubstrings[5].toString()
        versionDisplay = DOCSBRANCHDISPLAYNAMES[version]
    }

    if (!url.includes("/midpoint/reference")) {
        $("#select-version").css("display", "none");
    } else {
        //$('#select-version-picker').selectpicker('val', versionDisplay);
    }

    $('#select-version-picker').on('changed.bs.select', function(e, clickedIndex, isSelected, previousValue) {
        let newVersion = $(this).find('option').eq(clickedIndex).text().toString();
        let newVersionEdited = DOCSBRANCHDISPLAYNAMES[newVersion].toString()
        console.log(newVersionEdited)
        console.log(url)
        console.log(version)
        window.location.href = url.replace(version, newVersionEdited)
    });
});