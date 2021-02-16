# (C) 2020 Evolveum
#
# Evolveum page Plugin for Jekyll
#
# This plugin is responsible for generating:
#  page.html: user-friendly, readable, hierarchical HTML page
#  page.xml: flat XML page for Google and other robots
#  robots.txt
#
# NOTE: This has to be a plugin, not just a couple of Liquid files, as Jekyll has this idealistic strict separation of design and content.


module Evolveum

    class SiteMapGenerator < Jekyll::Generator
        priority :lowest

        def generate(site)
            @site = site
            @site.pages << generateSiteMapXml() unless pageExists?("sitemap.xml")
            @site.pages << generateSiteMapHtml() unless pageExists?("sitemap.html")
            @site.pages << generateRobotsTxt() unless pageExists?("robots.txt")
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
              page = Jekyll::PageWithoutAFile.new(@site, __dir__, "", "sitemap.xml")
              page.content = File.read(sourceFilePath("sitemap.xml")).gsub(MINIFY_REGEX, "")
              page.data["layout"] = nil
              page.data["visibility"] = "system"
              page
            end

            def generateSiteMapHtml()
              page = Jekyll::PageWithoutAFile.new(@site, __dir__, "", "sitemap.html")
              page.content = File.read(sourceFilePath("sitemap.html")) # No minification here
              page.data["layout"] = "page"
              page.data["visibility"] = "auxiliary"
              page.data["title"] = "Site Map"
              page
            end

            def generateRobotsTxt()
              page = Jekyll::PageWithoutAFile.new(@site, __dir__, "", "robots.txt")
              page.content = File.read(sourceFilePath("robots.txt"))
              page.data["layout"] = nil
              page.data["visibility"] = "system"
              page
            end

        end
end
