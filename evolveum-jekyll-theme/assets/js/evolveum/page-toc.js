(function() {
  const toc = document.querySelector(".ev-page-toc");
  if (!toc || !("IntersectionObserver" in window)) {
    return;
  }

  const entries = [];
  toc.querySelectorAll('a[href^="#"]').forEach(function(link) {
    const heading = document.getElementById(decodeURIComponent(link.hash.slice(1)));
    if (heading) {
      entries.push({ link: link, heading: heading });
    }
  });
  if (!entries.length) {
    return;
  }

  const visible = new Set();

  function setCurrent(link) {
    entries.forEach(function(entry) {
      if (entry.link === link) {
        entry.link.setAttribute("aria-current", "true");
      } else {
        entry.link.removeAttribute("aria-current");
      }
    });
  }

  const observer = new IntersectionObserver(function(changes) {
    changes.forEach(function(change) {
      if (change.isIntersecting) {
        visible.add(change.target);
      } else {
        visible.delete(change.target);
      }
    });
    const current = entries.find(function(entry) {
      return visible.has(entry.heading);
    });
    if (current) {
      setCurrent(current.link);
    }
  }, { rootMargin: "-69px 0px -70% 0px" });

  entries.forEach(function(entry) {
    observer.observe(entry.heading);
  });
})();
