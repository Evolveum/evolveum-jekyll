# (C) 2026 Evolveum
#
# Evolveum Jekyll Plugin — PageCache
# O(1) hash-based cache for page lookups during Jekyll builds.
# Replaces O(n) linear page lookups with O(1) hash lookups.
# Should save tens of seconds with docs builds
# The caching isnt perfect, for example page aliases were deliberatly not added.
# Currently the number of cached requests is 98.4% on local build,
# so I think it would be contraproductive to complicate the caching further for now.
# Maybe in the future when the performance benefit is more significant, we can optimize caching further.

module Evolveum

    class PageCache
        @page_cache = {}
        @url_cache = {}
        @built = false


        class << self

            # Build path and URL cache indices from the site's pages.
            def build(site)
                @page_cache = {}
                @url_cache = {}
                @built = false

                site.pages.each do |page|
                    @page_cache[page.path] = page
                    @url_cache[page.url] = page
                end

                @built = true
            end

            # O(1) lookup by page.path
            def by_path(path)
                return @page_cache[path] if @built
                nil
            end

            # O(1) lookup by page.url
            def by_url(url)
                return @url_cache[url] if @built
                nil
            end

        end
    end

    Jekyll::Hooks.register :site, :pre_render, priority: :lowest do |site|
        Evolveum::PageCache.build(site)
    end

end
