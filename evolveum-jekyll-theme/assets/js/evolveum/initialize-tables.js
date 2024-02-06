window.addEventListener('load', function() {
    $(".sortableTableSmallDefaultLength").DataTable({
        "lengthMenu": [ 10, 25, 50, 75, 100 ]
    });

    $(".sortableTableMediumDefaultLength").DataTable({
        "lengthMenu": [ 35, 10, 25, 50, 75, 100 ]
    });

    $(".sortableTableLargeDefaultLength").DataTable({
        "lengthMenu": [ 100, 10, 25, 50, 75 ]
    });
})