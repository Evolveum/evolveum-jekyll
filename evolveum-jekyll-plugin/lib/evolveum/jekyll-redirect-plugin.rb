# (C) 2021 Evolveum
#
# Evolveum page Plugin for Jekyll
#
# TODO
#
# NOTE: This has to be a plugin, not just a couple of Liquid files, as Jekyll has this idealistic strict separation of design and content.
require_relative 'jekyll-versioning-plugin.rb'

module Evolveum

    @pageRedirects = []

    def self.getPageRedirects()
        return @pageRedirects
    end

    def self.setPageRedirects(newPageRedirects)
        @pageRedirects = newPageRedirects
    end

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
            page.data["redirects"], pRedirects = collectRedirects()

            Evolveum.setPageRedirects(pRedirects)

            if site.config['environment']['name'].include?("docs")
                page.data["defaultBranch"] = findDefaultBranch(site)
            end

            @site.pages << page
        end

        def findDefaultBranch(site)
            docsDir = site.config['docs']['docsPath'] + site.config['docs']['docsDirName']
            verObject = YAML.load_file("#{docsDir}/_data/midpoint-versions.yml")
            defaultBranch = ""
            verObject.each do |ver|
                if ver['defaultBranch'] != nil && ver['defaultBranch'] == true
                    defaultBranch = ver['docsBranch']
                end
            end
            if defaultBranch == ""
                return "master"
            else
                return defaultBranch
            end
        end

        def collectRedirects()
            redirects = []
            pageRedirects = []
            @site.pages.each do |page|
                if page.data['moved-from']
                    normalizeMovedFrom(page.data['moved-from']).each do |movedFrom|
                        redirect = createRedirect(movedFrom, page)
                        redirects << redirect unless redirect.nil?
                        pageRedirects << createPageRedirect(movedFrom, page)
                    end
                end
            end
            return redirects, pageRedirects
        end

        # The :page-moved-from: header attribute is passed to Jekyll page data as a single String
        # (repeated header lines collapse to the last value, so all old URLs must fit on one line).
        # Accepts: a single URL, a comma-separated list of URLs (like :page-keywords:),
        # or a YAML array (legacy). Returns a list of old URLs.
        def normalizeMovedFrom(value)
            if value.is_a?(Array)
                value.compact.map { |v| v.to_s.strip }.reject { |v| v.empty? }
            else
                value.to_s.split(',').map { |v| v.strip }.reject { |v| v.empty? }
            end
        end

        def createPageRedirect(movedFrom, page)
            movedFrom = insertReferenceBranch(movedFrom, page)

            if movedFrom.end_with?('*')
                movedFrom = movedFrom.sub("*", ".*")
            end
            return { "pattern" => movedFrom,  "substitution" => page.url }
        end

        def insertReferenceBranch(url, page)
            negativeLookAhead = VersionReader.get_config_value('negativeLookAhead')

            if url.include?('midpoint/reference/') && !url.include?('midpoint/reference/index.html') && url.match(negativeLookAhead)
                branch = nil
                if page.data['midpointBranchSlug'] != nil
                    branch = page.data['midpointBranchSlug']
                else
                    branch = findDefaultBranch(@site)
                end
                url = url.sub("midpoint/reference/", "midpoint/reference/#{branch}/")
            end

            return url
        end

        def createRedirect(movedFrom, page)
            out = insertReferenceBranch(movedFrom, page)

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

            # Handle the case when the moved-from URL is the same as the new URL. if unhandled, this would create a redirect loop, so we need to log an error and ignore the redirect.
            if "/#{out}/" == page.url
              Jekyll.logger.error "Page redirect error: original URL '#{movedFrom}' redirects to the same URL '#{page.url}', ignoring redirect. Please fix the :page-moved-from: attribute in the page front matter. Page url: #{page.url}"
              return nil
            end

            return { "pattern" => "^" + escapePattern(out) + "/?$",  "substitution" => page.url }
        end

        def escapePattern(orig)
            orig.gsub(/\+/,'\\+').gsub(/-/,'\\-')
        end
    end

end
