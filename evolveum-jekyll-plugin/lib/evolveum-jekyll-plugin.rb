module Evolveum

    class SiteDumpGenerator < Jekyll::Generator
        priority :low

        def generate(site)
            site.pages << SiteDumpPage.new(site, site.source, 'misc')
        end

    end

    class SiteDumpPage < Jekyll::Page

        def initialize(site, base, dir)
            @site = site
            @base = base
            @dir  = dir
            @name = 'sitedump.html'

            self.process(@name)
            self.read_yaml(File.join(base, '_layouts'), 'sitedump.html')
            self.data['title'] = "Site dump"
            self.data['foo'] = "BAR"

            self.data['navtree'] = site.data['nav']

#             navtree = []
#
#             site.pages.each do |page|
#                 index_page(navtree, page)
#             end
#
#             self.data['navtree'] = navtree
        end


    end

    # Experimental, diag
    class NavTag < Liquid::Tag

        def initialize(tag_name, text, tokens)
          super
          @text = text
        end

        def render(context)
            site = context['site']
            page = context['page']
            navtree = site['data']['nav']
            navtree.pretty_print
        end
    end

    # Sitemap page (long hierarchical list of all pages)
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
            if (!nav.subnodes.empty?)
                s << nav.indent(indent + 1)
                s << "<ul>\n"
                nav.subnodes.each do |subnode|
                    sitemap_indent(s, subnode, indent + 2)
                end
                s << nav.indent(indent + 1)
                s << "</ul>\n"
            end
        end

    end


    class BreadcrumbsTag < Liquid::Tag

        def initialize(tag_name, text, tokens)
          super
          @text = text
        end

        def render(context)
            navtree = context['site']['data']['nav']
            s = StringIO.new
            s << '<ol class="breadcrumb">'
            breadcrumbs = navtree.breadcrumbs(context['page']['url'])
            breadcrumbs.each do |crumb|
                s << '<li class="breadcrumb-item">'
                crumb.append_label_link(s)
                s << '</li>'
            end
            s << '</ol>'
            s.string
        end
    end


    class NavtreeTag < Liquid::Tag

        def initialize(tag_name, text, tokens)
          super
          @text = text
        end

        def render(context)
            navtree = context['site']['data']['nav']
            currentPageUrl = context['page']['url']
            currentPageSlugs = navtree.slugize(currentPageUrl)

            s = StringIO.new
            s << "<ul>\n"
            navtree.visible_subnodes.each do |topnode|
                append_li_label_start(s, topnode, currentPageUrl, 1)
                if (topnode.subnodes.empty?)
                    s << "</li>\n"
                else
                    if (topnode.url == currentPageUrl)
                        append_subnodes(s, topnode, 2)
                        s << topnode.indent(1)
                        s << "</li>\n"
                    elsif topnode.slug == currentPageSlugs[0]
                        dive(s, topnode, 1, currentPageUrl, currentPageSlugs)
                        s << topnode.indent(1)
                        s << "</li>\n"
                    else
                        s << "</li>\n"
                    end
                end
            end
            s << "</ul>\n"
            s.string
        end

        def dive(s, topnode, level, currentPageUrl, currentPageSlugs)
            if topnode.visible_subnodes.any? { |nav| nav.active?(currentPageUrl) }
                # We have active node at this level.
                # Therefore we want to list the whole level
                s << topnode.indent(level * 2 + 1)
                s << "<ul>\n"
                topnode.visible_subnodes.each do |node|
                    append_li_label_start(s, node, currentPageUrl, level * 2 + 2)
                    if (node.active?(currentPageUrl))
                        if (node.subnodes.empty?)
                            # We would like to display subnodes, but there are none
                            s << "</li>\n"
                        else
                            # Display immediate subnodes under current node
                            append_subnodes(s, node, level * 2 + 3)
                            s << node.indent(level * 2 + 2)
                            s << "</li>\n"
                        end
                    else
                        dive(s, node, level + 1, currentPageUrl, currentPageSlugs)
                        s << node.indent(level * 2 + 2)
                        s << "</li>\n"
                    end
                end
                s << topnode.indent(level * 2 + 1)
                s << "</ul>\n"
            else
                # Active node is not on this level.
                # Display just a single "slug" that lies on the way down and dive deeper.
                node = topnode.visible_subnodes.find { |nav| nav.slug == currentPageSlugs[level] }
                if (node == nil) then return end
                s << node.indent(level * 2 + 1)
                s << "<ul>\n"
                append_li_label_start(s, node, currentPageUrl, level * 2 + 2)
                dive(s, node, level + 1, currentPageUrl, currentPageSlugs)
                s << node.indent(level * 2 + 2)
                s << "</li>\n"
                s << node.indent(level * 2 + 1)
                s << "</ul>\n"
            end
        end

        def append_subnodes(s, topnode, indent)
            s << topnode.indent(indent)
            s << "<ul>\n"
            topnode.subnodes.each do |node|
                append_li_label_start(s, node, nil, indent + 1)
                s << "</li>\n"
            end
            s << topnode.indent(indent)
            s << "</ul>\n"
        end

        def append_li_label_start(s, node, currentPageUrl, indent)
            s << node.indent(indent)
            s << "<!--"
            s << node.display_order.to_s
            s << "-->"
            if (node.active?(currentPageUrl))
                s << '<li class="active">'
            else
                s << "<li>"
            end
            node.append_label_link(s)
        end

    end


    class Nav
        attr_reader :subnodes, :slug
        attr_accessor :url, :title, :visibility, :display_order

        def initialize(slug)
            @subnodes = []
            @slug = slug
            @url = nil
            @title = nil
        end

        def self.construct(site)
            navtree = Evolveum::Nav.new(nil)
            site.pages.each do |page|
                puts("  url=#{page.url}")
                navtree.index_page(page)
            end
            return navtree
        end

        def index_page(page)
            nav = index_path(page.url)
            nav.url = page.url
            nav.title = page.data['nav-title'] || page.data['title']
            nav.visibility = page.data['visibility'] || "visible"
            nav.display_order = page.data['display-order'].to_i
            if (nav.display_order == 0)
                nav.display_order = 100
            end
        end

        def index_path(url)
            slugs = slugize(url)
            nav = self
            slugs.each do |slug|
                sub = nav.resolve(slug)
                if (sub == nil)
                    sub = Evolveum::Nav.new(slug)
                    nav.add(sub)
                end
                nav = sub
            end
            nav
        end

        def slugize(url)
            url.split('/').select { |slug| !slug.empty? }
        end

        def resolve(slug)
            @subnodes.find { |nav| nav.slug == slug }
        end

        def add(subnode)
            @subnodes << subnode
        end

        def to_liquid()
            return self
        end

        def pretty_print()
            s = StringIO.new
            pretty_print_indent(s, 0)
            s.string
        end

        def pretty_print_indent(s, indent)
            s << indent(indent)
            if (@slug == nil)
                s << "(root)"
            else
                s << @slug
            end
            s << "\n"
            @subnodes.each do |subnode|
                subnode.pretty_print_indent(s, indent + 1)
            end
        end

        def label
            (@title == nil || @title.empty?) ? @slug : @title
        end

        def label_encoded
            label.encode(:xml => :text)
        end

        def append_label_link(s)
                if (@url != nil)
                    s << "<a href=\"#{@url}\">"
                end
                s << label_encoded
                if (@url != nil)
                    s << "</a>"
                end
        end

        def indent(indent)
            "  " * indent
        end

        def breadcrumbs(url)
            slugs = slugize(url)
            breadcrumbs = []
            nav = self
            slugs.each do |slug|
                nav = nav.resolve(slug)
                breadcrumbs << nav
            end
            breadcrumbs
        end

        def active?(currentPageUrl)
            @url != nil && @url == currentPageUrl
        end

        def visible?
            @visibility == "visible"
        end

        def <=> other
            order = self.display_order <=> other.display_order
            if (order == 0)
                self.label.downcase <=> other.label.downcase
            else
                order
            end
        end

        def visible_subnodes
            subnodes.select{ |node| node.visible? }.sort
        end

    end

end

Liquid::Template.register_tag('nav', Evolveum::NavTag)
Liquid::Template.register_tag('sitemap', Evolveum::SitemapTag)
Liquid::Template.register_tag('breadcrumbs', Evolveum::BreadcrumbsTag)
Liquid::Template.register_tag('navtree', Evolveum::NavtreeTag)

Jekyll::Hooks.register :site, :pre_render do |site|
    puts "=========[ EVOLVEUM ]============== pre_render #{site}"
    site.data['nav'] = Evolveum::Nav.construct(site)
end
