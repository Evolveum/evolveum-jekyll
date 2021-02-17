# (C) 2021 Evolveum
#
# Evolveum page Plugin for Jekyll
#
# This plugin is responsible for generating:
#  sitemap.html: user-friendly, readable, hierarchical HTML page
#  sitemap.xml: flat XML page for Google and other robots
#  searchmap.xml: flat XML for our custom quicksearch
#  robots.txt
#
# NOTE: This has to be a plugin, not just a couple of Liquid files, as Jekyll has this idealistic strict separation of design and content.


module Evolveum

    class SiteMapGenerator < Jekyll::Generator
        priority :lowest

        FILENAME_SITEMAP_XML = 'sitemap.xml'
        FILENAME_SITEMAP_HTML = 'sitemap.html'
        FILENAME_SEARCHMAP = 'searchmap.xml'
        FILENAME_ROBOTS = 'robots.txt'

        def generate(site)
            @site = site
            @site.pages << generateSiteMapXml() unless pageExists?(FILENAME_SITEMAP_XML)
            @site.pages << generateSiteMapHtml() unless pageExists?(FILENAME_SITEMAP_HTML)
            @site.pages << generateSearchMap() unless pageExists?(FILENAME_SEARCHMAP)
            @site.pages << generateRobots() unless pageExists?(FILENAME_ROBOTS)
        end

        private

            MINIFY_REGEX = %r!(?<=>\n|})\s+!.freeze

            def sourceFilePath(filename)
              File.expand_path filename, __dir__
            end

            # Checks if a file already exists in the site source
            def pageExists?(file_path)
              @site.pages.any? { |p| p.url == "/#{file_path}" }
            end

            def generateSiteMapXml()
              page = Jekyll::PageWithoutAFile.new(@site, __dir__, "", FILENAME_SITEMAP_XML)
              page.content = File.read(sourceFilePath(FILENAME_SITEMAP_XML)).gsub(MINIFY_REGEX, "")
              page.data["layout"] = nil
              page.data["visibility"] = "system"
              page
            end

            def generateSearchMap()
              page = Jekyll::PageWithoutAFile.new(@site, __dir__, "", FILENAME_SEARCHMAP)
              page.content = File.read(sourceFilePath(FILENAME_SEARCHMAP)) # No minification here
              page.data["layout"] = nil
              page.data["visibility"] = "system"
              page
            end


            def generateSiteMapHtml()
              page = Jekyll::PageWithoutAFile.new(@site, __dir__, "", FILENAME_SITEMAP_HTML)
              page.content = File.read(sourceFilePath(FILENAME_SITEMAP_HTML)) # No minification here
              page.data["layout"] = "page"
              page.data["visibility"] = "auxiliary"
              page.data["title"] = "Site Map"
              page
            end

            def generateRobots()
              page = Jekyll::PageWithoutAFile.new(@site, __dir__, "", FILENAME_ROBOTS)
              page.content = File.read(sourceFilePath(FILENAME_ROBOTS))
              page.data["layout"] = nil
              page.data["visibility"] = "system"
              page
            end

        end
end
