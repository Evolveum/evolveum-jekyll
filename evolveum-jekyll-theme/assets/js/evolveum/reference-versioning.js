window.addEventListener('load', function () {
    let url = window.location.href
    let urlSubstrings = url.split("/")
    let version = ""
    if (urlSubstrings.length > 6) {
        version = urlSubstrings[5].charAt(0).toUpperCase() + urlSubstrings[5].slice(1) //Maybe problem when number is first?
    }

    if (!url.includes("/midpoint/reference")) {
        $("#select-version").css("display","none");
    } else {
        $('#select-version-picker').selectpicker('val', version);
    }

    $('#select-version-picker').on('changed.bs.select', function(e, clickedIndex, isSelected, previousValue) {
        let newVersion = $(this).find('option').eq(clickedIndex).text();
        //console.log(newVersion)
        let versionEdited = version.charAt(0).toLowerCase() + urlSubstrings[5].slice(1)
        let newVersionEdited = newVersion.charAt(0).toLowerCase() + urlSubstrings[5].slice(1)
        window.location = url.replace(versionEdited, newVersionEdited)
    });
});