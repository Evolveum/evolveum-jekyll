$(document).ready(function() {

    let adocDataTableConfigs = document.getElementsByClassName('datatable-config');

    Array.from(adocDataTableConfigs).forEach(function(configObject) {
        if (configObject.tagName === 'TABLE') {
            $(configObject).removeClass('datatable-config');
            configObject.classList.add('dataTable');
        } else {
            const configStringData = $(configObject).children().first().text();
            let configData;
            try {
                configData = JSON.parse(configStringData);
            } catch (error) {
                console.warn("Invalid JSON:", error.message);
                configData = {};
            }
            let datatableObject = $(configObject).next();
            if (datatableObject.prop('tagName') === 'TABLE') {
                for (const [key, value] of Object.entries(configData)) {
                    datatableObject.attr('data-' + key, value);
                }
                datatableObject.addClass('dataTable');
            }
        }
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
        let orderColumn = 0; // Defaults to the first column, is the same as setting order-column to 1
        let originalOrder = true;
        let autoWidth = true;

        // We need to remove the colgroup element from the table, because DataTables will add it again
        datatable.find('colgroup').remove();

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

                if (datatable.attr('data-length-menu-auto') != undefined && datatable.attr('data-length-menu-auto') != 'false') {
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
            orderColumn = parseInt(datatable.attr('data-order-column'), 10) - 1;
            originalOrder = false;
        }

        if (datatable.attr('data-order') != undefined) {
            order = datatable.attr('data-order');
            originalOrder = false;
        }

        if (datatable.attr('data-page-length') != undefined) {
            pageLength = parseInt(datatable.attr('data-page-length'), 10);
        }        

        if (datatable.attr('data-paging') === 'true') {
            paging = true;
        }

        if (datatable.attr('data-searchable') === 'true') {
            searchable = true;
        }

        if (datatable.attr('data-auto-width') === 'false') {
            autoWidth = false;
        }

        let layout = {
            topStart: paging ? 'pageLength' : null,
            topEnd: searchable ? 'search' : null,
            bottomStart: paging ? 'info' : null,
            bottomEnd: paging ? 'paging' : null
        }

        if (datatable.attr('data-custom-layout') != undefined && datatable.attr('data-custom-layout') === 'true') {
            try {
                let customLayout = JSON.parse(datatable.attr('data-layout'));
                layout = { ...layout, ...customLayout };
            } catch (error) {
                console.error("Invalid JSON in data-layout attribute:", error.message);
            }
        }
        
        // Remove data attributes from the table
        datatable.removeAttr('data-length-menu data-length-menu-max data-length-menu-min data-length-menu-auto data-length-menu-length data-order-column data-page-length data-order data-paging data-custom-layout data-layout data-searchable data-auto-width');

        // Log the values before initializing DataTable
        console.log('Original order:', originalOrder);
        console.log('Order Column:', orderColumn);
        console.log('Order:', order);
        console.log('Page Length:', pageLength);
        console.log('Paging:', paging);
        console.log('Length menu:', lengthMenu);
        console.log('Layout:', layout);

        const orderConfig = originalOrder ? [] : [[orderColumn, order]];

        let finalTable = datatable.DataTable({
            searching: searchable,
            paging: paging,
            lengthMenu: lengthMenu,
            pageLength: pageLength,
            order: orderConfig,
            layout: layout,
            autoWidth: autoWidth
        });

        if (!autoWidth) {
            datatable.css({
                'width': 'auto !important'
            });
            let tableWidth = datatable.width();
            // Should work but it isnt too reliable
            datatable.parent().parent().parent().css({
                'width': tableWidth
            });
        }
    });
});