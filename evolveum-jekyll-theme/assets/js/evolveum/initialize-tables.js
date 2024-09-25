$(document).ready(function() {

    let adocDataTableConfigs = document.getElementsByClassName('datatable-config');

    Array.from(adocDataTableConfigs).forEach(function(configObject) {
        const configStringData = $(configObject).children().first().text();
        const configData = JSON.parse(configStringData);
        let datatableObject = $(configObject).next();
        for (const [key, value] of Object.entries(configData)) {
            datatableObject.attr('data-' + key, value);
        }
        datatableObject.addClass('dataTable');
    });

    let datatables = $('.dataTable');

    // TODO add scroll

    datatables.each(function() {
        let datatable = $(this);
        let paging = false;
        let searchable = false;
        let lengthMenu = [10, 25, 50, 100];
        let lengthMax = 100;
        let lengthMin = 10;
        let lengthMenuLength = 4; // Only active when lengthMenuAuto is set to true
        let order = "asc";
        let pageLength = 10;
        let orderColumn = 0;

        if (paging) {
            if (datatable.attr('data-length-menu') != undefined) {
                lengthMenu = datatable.attr('data-length-menu').split(',').length > 0 ? datatable.attr('data-length-menu').split(',').map(Number) : lengthMenu;

            } else {
                if (datatable.attr('data-length-menu-max') != undefined) {
                    lengthMax = parseInt(datatable.attr('data-length-menu-max'), 10);
                }

                if (datatable.attr('data-length-menu-min') != undefined) {
                    lengthMin = parseInt(datatable.attr('data-length-menu-min'), 10);
                }

                if (datatable.attr('data-length-menu-auto') != undefined || datatable.attr('data-length-menu-auto') != 'false') {
                    if (datatable.attr('data-length-menu-length') != undefined) {
                        lengthMenuLength = parseInt(datatable.attr('data-length-menu-length'), 10);
                    }

                    let step = (lengthMax - lengthMin) / (lengthMenuLength - 2);

                    lengthMenu = [lengthMin];

                    for (let i = lengthMin; i < lengthMax; i += step) {
                        lengthMenu.push(i);
                    }

                    lengthMenu.push(lengthMax);
                }
            }

            pageLength = lengthMenu[0];
        }

        if (datatable.attr('data-order-column') != undefined) {
            orderColumn = parseInt(datatable.attr('data-order-column'), 10);
        }

        if (datatable.attr('data-pageLength') != undefined) {
            pageLength = parseInt(datatable.attr('data-pageLength'), 10);
        }

        if (datatable.attr('data-order') != undefined) {
            order = datatable.attr('data-order');
        }

        if (datatable.attr('data-paging') === 'true') {
            paging = true;
        }

        if (datatable.attr('data-searchable') === 'true') {
            searchable = true;
        }

        // Remove data attributes from the table
        datatable.removeAttr('data-length-menu data-length-menu-max data-length-menu-min data-length-menu-auto data-length-menu-length data-order-column data-pageLength data-order data-paging');

        // Log the values before initializing DataTable
        console.log('Order Column:', orderColumn);
        console.log('Order:', order);
        console.log('Page Length:', pageLength);
        console.log('Paging:', paging);
        console.log('Length menu:', lengthMenu);

        datatable.DataTable({
            searching: searchable,
            paging: paging,
            lengthMenu: lengthMenu,
            pageLength: pageLength,
            order: [
                [orderColumn, order]
            ]
        });
    });
});