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

    class PreviewGenerator < Jekyll::Generator
        priority :low

        def generate(site)
            @site = site
            @site.pages.each do |page|
                if page.data["description"] == nil
                    if page.data["preview"] == nil
                        preview = generatePreview(page)
#                        puts("PPPP:\n#{preview}")
                        page.data["preview"] = preview
                    end
                else
                    page.data["preview"] = page.data["description"]
                end
            end
        end

        def generatePreview(page)
            out = page.content

            # Remove Liquid formatting
            out = out.gsub(/\{\{[^\}]*\}\}/, '')
            out = out.gsub(/\{\%[^\}]*\%\}/, '')

            # Remove HTML formatting
            out = out.gsub(/\<[^\>]*\>/, '')

            # Remove URLs
            out = out.gsub(/http:\/\/[\S]+/, '')
            out = out.gsub(/https:\/\/[\S]+/, '')

            if out.start_with?('=')
                # asciidoc
                out = purifyAsciidoc(out)
            end

            # Useless characters
            out = out.gsub(/[\|\#\^\*\~]/, '')

            # shrink whitespace
            out = out.gsub(/\s+/, ' ')
            return truncate(out.strip, 256)
        end

        def purifyAsciidoc(input)
            out = ""
            input.lines.each do |line|
                lineout = ''
                if line.start_with?('= ')
                    # Asciidoc title, it is already in the page title metadata, no need to repeat that in description
                elsif line.match?(/^:[\w\-]+:/)
                    # Asciidoc variables, not interesting
                elsif line.match?(/^\+\+[\+]+/) || line.match?(/^\-\-[\-]+/)
                    # Asciidoc passthrough and similar formatting
                elsif line.match?(/^\|\=[\=]+/) || line.match?(/^\=[\=]+\|/)
                    # Table start and end
                elsif line.match?(/^[\w]+::/)
                    # block macro
                else
                    # Remove heading formatting marks
                    lineout = line.gsub(/^=+\s+/, '')
                    # Remove *bold* markup
                    lineout = lineout.gsub(/\*([\w\s:]+?)\*/, '\1')
                    # Remove _italics_ markup
                    lineout = lineout.gsub(/\_([\w\s:]+?)\_/, '\1')
                    # Remove `code` markup
                    lineout = lineout.gsub(/\`([\w\s:]+?)\`/, '\1')
                    # Remove inline macros, keeping the content
                    lineout = lineout.gsub(/\w+:[\S]+?\[([^\]]+)\]/, '\1')
                    # Asciidoc variables
                    lineout = lineout.gsub(/\{[^\}]*\}/, '')
                    # [cols="1,1,2"] and similar
                    lineout = lineout.gsub(/^\[[^\]]*\]/, '')
                    # .labels
                    lineout = lineout.gsub(/^\./, '')
                end
                out << lineout
            end
            return out
        end

        def truncate(s, length)
          if s.length > length
            s.to_s[0..length].gsub(/[^\w]\w+\s*$/, '...')
          else
            s
          end
        end
    end

    class SiteMapGenerator < Generator
        priority :lowest

        FILENAME_SITEMAP_XML = 'sitemap.xml'
        FILENAME_SITEMAP_HTML = 'sitemap.html'
        FILENAME_SEARCHMAP = 'searchmap.json'
        FILENAME_ROBOTS = 'robots.txt'

        def generate(site)
            @site = site
            @nav = site.data['nav']
            @site.pages << generateSiteMapXml() unless pageExists?(FILENAME_SITEMAP_XML)
            @site.pages << generateSiteMapHtml() unless pageExists?(FILENAME_SITEMAP_HTML)
            @site.pages << generateSearchMap() unless pageExists?(FILENAME_SEARCHMAP)
            @site.pages << generateRobots() unless pageExists?(FILENAME_ROBOTS)
        end

        private

        MINIFY_REGEX = %r!(?<=>\n|})\s+!.freeze

        SEARCHMAP_PROPS = [ 'title', 'author', 'description', 'keywords', 'preview' ]

        def generateSiteMapXml()
          page = Jekyll::PageWithoutAFile.new(@site, __dir__, "", FILENAME_SITEMAP_XML)
          page.content = File.read(sourceFilePath(FILENAME_SITEMAP_XML)).gsub(MINIFY_REGEX, "")
          page.data["layout"] = nil
          page.data["visibility"] = "system"
          mappages = []
          @nav.processAllVisibleNavs { |nav| mappages << nav.page }
          page.data["mappages"] = mappages
          page
        end

        def generateSearchMap()
          page = Jekyll::PageWithoutAFile.new(@site, __dir__, "", FILENAME_SEARCHMAP)
          page.content = File.read(sourceFilePath(FILENAME_SEARCHMAP)) # No minification here
          page.data["layout"] = nil
          page.data["visibility"] = "system"
          page.data["searchmap"] = constructSearchMap()
          page
        end

        def constructSearchMap
            searchmap = []
            @nav.processAllVisibleNavs do |nav|
                page = nav.page
                pageEntry = { url: page.url, lastModificationDate: page.data['lastModificationDate'] }
                SEARCHMAP_PROPS.each do |prop|
                    if page.data[prop]
                        if page.data[prop].kind_of?(Array)
                            pageEntry[prop] = page.data[prop].map { |e| e.to_s }
                        else
                            pageEntry[prop] = page.data[prop].to_s
                        end
                    end
                end
                searchmap << pageEntry
            end
            return searchmap
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

    ##
    # Sitemap Liquid tag (long hierarchical list of all pages)
    #
    # This is a code for {% sitemap %} Liquid tag.
    # This tag is not used on ordinary pages.
    # It is usually used on a dedicated sitemap.html page.
    class SitemapTag < Liquid::Tag

        def initialize(tag_name, text, tokens)
          super
          @text = text
        end

        def render(context)
            navtree = context['site']['data']['nav']
            s = StringIO.new
            s << "<ul>\n"
            sitemap_indent(s, navtree, 0)
            s << "</ul>\n"
            s.string
        end

        def sitemap_indent(s, nav, indent)
            if (nav.slug != nil)
                s << nav.indent(indent)
                s << "<li>"
                nav.append_label_link(s)
                s << "</li>\n"
            end
            presentableSubnodes = nav.presentableSubnodes
            if (!presentableSubnodes.empty?)
                s << nav.indent(indent + 1)
                s << "<ul>\n"
                presentableSubnodes.each do |subnode|
                    sitemap_indent(s, subnode, indent + 2)
                end
                s << nav.indent(indent + 1)
                s << "</ul>\n"
            end
        end

    end


end

# Registering custom Liquid tags with Jekyll

Liquid::Template.register_tag('sitemap', Evolveum::SitemapTag)
