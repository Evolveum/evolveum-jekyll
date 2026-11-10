(function() {

    function regionName(el, index) {
        if (el.dataset.evLabel) {
            return el.dataset.evLabel;
        }
        const block = el.closest('.listingblock, .tableblock, .table-container');
        const title = block && block.querySelector(':scope > .title, caption');
        if (title && title.textContent.trim()) {
            return title.textContent.trim();
        }
        return (el.tagName === 'PRE' ? 'Code example ' : 'Table ') + index;
    }

    function update() {
        let codeIndex = 0;
        let tableIndex = 0;
        const used = new Set();
        document.querySelectorAll('main pre, main .table-container').forEach(function(el) {
            const index = el.tagName === 'PRE' ? ++codeIndex : ++tableIndex;
            const scrolls = el.scrollWidth > el.clientWidth + 1;
            if (scrolls) {
                el.setAttribute('data-ev-scroll', '');
                el.setAttribute('tabindex', '0');
                el.setAttribute('role', 'region');
                let name = regionName(el, index);
                if (used.has(name)) {
                    name += ' (' + index + ')';
                }
                used.add(name);
                el.setAttribute('aria-label', name);
            } else if (el.hasAttribute('data-ev-scroll')) {
                el.removeAttribute('data-ev-scroll');
                el.removeAttribute('tabindex');
                el.removeAttribute('role');
                el.removeAttribute('aria-label');
            }
        });
    }

    let timer;
    window.addEventListener('load', update);
    window.addEventListener('resize', function() {
        clearTimeout(timer);
        timer = setTimeout(update, 200);
    });

})();
