(function() {

    $(document).on('click', '[data-ev-toggle]', function() {
        const target = document.getElementById(this.getAttribute('aria-controls'));
        const open = target.classList.toggle('show');
        this.setAttribute('aria-expanded', String(open));
    });

})();
