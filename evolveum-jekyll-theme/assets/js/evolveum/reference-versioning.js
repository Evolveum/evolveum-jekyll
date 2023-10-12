var DOCSBRANCHESCOLORS = new Map();

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
    let start = 60
    let end = 210
    console.log(options.length)
    let step = Math.round((end - start) / options.length)
    console.log("ADB" + options)
    for (let o = 0; o < options.length; o++) {
        console.log(start + (o*step))
        console.log(o)
        DOCSBRANCHESCOLORS.set(options[o].value, rgbToHex(start + (o*step),start + (o*step),start + (o*step) + 20))
    }
    let url = window.location.href
    let urlSubstrings = url.split("/")
    let version = ""
    if (urlSubstrings.length > 6) {
        version = urlSubstrings[5].charAt(0).toUpperCase() + urlSubstrings[5].slice(1) //Maybe problem when number is first?
    }

    if (!url.includes("/midpoint/reference")) {
        $("#select-version").css("display", "none");
    } else {
        $('#select-version-picker').selectpicker('val', version);
    }

    $('#select-version-picker').on('changed.bs.select', function(e, clickedIndex, isSelected, previousValue) {
        let newVersion = $(this).find('option').eq(clickedIndex).text();
        console.log(newVersion)
        let versionEdited = version.charAt(0).toLowerCase() + version.slice(1)
        console.log(versionEdited)
        let newVersionEdited = newVersion.charAt(0).toLowerCase() + newVersion.slice(1)
        console.log(newVersionEdited)
        console.log(url)
        window.location = url.replace(versionEdited, newVersionEdited)
    });
});