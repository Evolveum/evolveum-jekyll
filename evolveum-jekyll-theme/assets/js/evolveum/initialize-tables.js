window.addEventListener('load', function() {
    let datatables = $('.dataTable');

    // TODO add scroll

    datatables.each(function() {
        let datatable = $(this);
        let paging = false;
        let lengthMenu = [10, 25, 50, 100];
        let lengthMax = 100;
        let lengthMin = 10;
        let lengthMenuLength = 4; // Only active when lengthMenuAuto is set to true
        let order = "asc";
        let pageLength = 10
        let orderColumn = 0;

        if (paging) {
            if (datatable.attr('data-length-menu') != undefined) {
                lengthMenu = datatable.attr('data-length-menu').split(',').length > 0 ? datatable.attr('data-length-menu').split(',') : lengthMenu;
            } else {
                if (datatable.attr('data-length-menu-max') != undefined) {
                    lengthMax = datatable.attr('data-length-menu-max').toInteger();
                }
    
                if (datatable.attr('data-length-menu-min') != undefined) {
                    lengthMin = $(datatable).attr('data-length-menu-min').toInteger();
                }
    
                if (datatable.attr('data-length-menu-auto') != undefined || datatable.attr('data-length-menu-auto') != 'false') {
                    if (datatable.attr('data-length-menu-length') != undefined) {
                        lengthMenuLength = datatable.attr('data-length-menu-length').toInteger();
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
            orderColumn = datatable.attr('data-order-column');
        }
        

        if (datatable.attr('data-pageLength') != undefined) {
            pageLength = datatable.attr('data-pageLength');
        }

        if (datatable.attr('data-order') != undefined) {
            order = datatable.attr('data-order');
        }
        
        if (datatable.attr('data-paging') === 'true') {
            paging = true;
        }

        datatable.DataTable({
            "paging": paging,
            lengthMenu: lengthMenu,
            pageLength: pageLength,
            order: [[orderColumn, order]]
        });
    });
})