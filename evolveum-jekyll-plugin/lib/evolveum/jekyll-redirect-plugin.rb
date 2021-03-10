# (C) 2021 Evolveum
#
# Evolveum page Plugin for Jekyll
#
# TODO
#
# NOTE: This has to be a plugin, not just a couple of Liquid files, as Jekyll has this idealistic strict separation of design and content.


module Evolveum

    class HtaccessGenerator < Generator
        priority :lowest

        FILENAME = '.htaccess'

        def generate(site)
            @site = site
            @nav = site.data['nav']

            page = Jekyll::PageWithoutAFile.new(@site, __dir__, "", FILENAME)
            page.content = File.read(sourceFilePath(FILENAME))
            page.data["layout"] = nil
            page.data["visibility"] = "system"
            page.data["redirects"] = collectRedirects()

            @site.pages << page
        end

        def collectRedirects()
            redirects = []
            @site.pages.each do |page|
                if page.data['moved-from']
                    Array(page.data['moved-from']).each do |movedFrom|
                        redirects << { "pattern" => "^" + escapePattern(prepareMovePath(movedFrom)) + "$",  "substitution" => page.url }
                    end
                end
            end
            return redirects
        end

        def prepareMovePath(orig)
            if orig.start_with?('/')
                # We do not want to start pattern with /
                # This is .htaccess, paths are relative to the directory in which .htaccess is
                return orig[1..-1]
            else
                return orig
            end
        end

        def escapePattern(orig)
            orig.gsub(/\+/,'\\+').gsub(/-/,'\\-')
        end
    end

end
