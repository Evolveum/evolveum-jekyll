$(document).ready(function() {
    const releaseNavTabs = document.querySelectorAll('.release-nav-tab');
    const releaseNavTables = document.querySelectorAll('.release-nav-table');

    releaseNavTables.forEach(table => {
        if (table.getAttribute('data-type') === 'supported' || table.getAttribute('data-type') === 'EOL') {
            const tbody = table.querySelector('tbody');
            let rows = Array.from(tbody.querySelectorAll('tr'));

            rows.reverse();

            rows.forEach(row => tbody.appendChild(row));
        }
    });

    releaseNavTabs.forEach((tab, index) => {
        tab.addEventListener('click', function() {
            releaseNavTables.forEach(table => {
                table.style.display = 'none';
            });
            releaseNavTables[index].style.display = 'inline-table';
            releaseNavTabs.forEach(tab => {
                tab.classList.remove('active');
            });
            tab.classList.add('active');
        });
    });
});
