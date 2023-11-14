var DOCSBRANCHESCOLORS = new Map();
var DOCSBRANCHDISPLAYNAMES = {}
var DEFAULTDOCSBRANCH = "master"

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
        console.log(options[o].dataset['tokens'])
        console.log(options[o])
        if (options[0].dataset['default'] != undefined && options[0].dataset['default'] == "default") {
            DEFAULTDOCSBRANCH = options[o].dataset['tokens']
        }
        DOCSBRANCHDISPLAYNAMES[options[o].value] = options[o].dataset['tokens']
        DOCSBRANCHDISPLAYNAMES[options[o].dataset['tokens']] = options[o].value
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
        $('#select-version-picker').selectpicker('val', versionDisplay);
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