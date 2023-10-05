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
                        redirects << createRedirect(movedFrom, page)
                    end
                end
            end
            return redirects
        end

        def createRedirect(movedFrom, page)
            out = movedFrom

            if out.start_with?('/')
                # We do not want to start pattern with /
                # This is .htaccess, paths are relative to the directory in which .htaccess is
                out = out[1..-1]
            end

            if out.end_with?('*')
                # This is special. We want do not want to redirect one specific document.
                # We want to redirect whole subtree. We have to leave the pattern open-ended
                out = out[0..-2]
                if out.end_with?('/')
                    out = out[0..-2]
                end
                return { "pattern" => "^" + escapePattern(out) + "(/|$)(.*)",  "substitution" => page.url + "$2" }
            end

            if out.end_with?('/')
                # We do not want the pattern to end with /
                # We will be adding patter suffix that represents both the URL ending and slash and without slash
                out = out[0..-2]
            end

            return { "pattern" => "^" + escapePattern(out) + "/?$",  "substitution" => page.url }
        end

        def escapePattern(orig)
            orig.gsub(/\+/,'\\+').gsub(/-/,'\\-')
        end
    end

end
