# (C) 2020-2021 Evolveum
#
# Evolveum Navigation Plugin for Jekyll
#
# This plugin is used to implement navigation functionality for Evolveum Jekyll sites.
# It deals with navigation, sitemap and similar things that cannot be done by
# exiting Jekyll plugins.
#
# This plugin is designed to work with Evolveum Jekyll theme.
#
# The basic idea:
#
# Navigation tree is built from Jekyll pages in :post_read and :pre_render hooks.
# The tree is a hierarchical structure of instances of Nav class.
# The tree represents the hierarchy of pages as Jekyll knows them.
# The tree is then used by other code to create navigation panel, breadcrumbs, list of child pages, etc.


module Evolveum

    ##
    # Page generator.
    # Generates stub pages for URLs that do not have their own pages.
    class StubGenerator < Jekyll::Generator
        priority :low

        def generate(site)
            @site = site
            site.data['nav'].uninitializedStubs.each do |nav|
                puts "Generating stub #{nav.url}"
                site.pages << generateStub(nav)
            end
        end

        def generateStub(nav)
            # WARNING: Magic follows.
            # We create new "virtual" page using PageWithoutAFile class.
            # This page has no source file, we will explicitly read the content from stub.html "template"
            stub = Jekyll::PageWithoutAFile.new(@site, __dir__, nav.url, "index.html")
            # The "stub.html" template is in the gem, in the same dir as this source code (hence __dir__)
            stub.content = File.read(File.join(__dir__, 'stub.html'))
            stub.data["layout"] = "page"
            stub.data['title'] = nav.slug
            nav.page = stub
            stub
        end
    end


    ##
    # Breadcrumbs Liquid tag.
    #
    # This is a code for {% breadcrumbs %} Liquid tag.
    # This tag renders a short list of breadcrumbs from current page to the top.
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


    ##
    # Navigation tree Liguid tag.
    #
    # This is a code for {% navtree %} Liquid tag.
    # It rendets navigation tree suitable for navigation panel.
    # This tree is "dynamic", it is sensitive to what current page is.
    # The part of the tree that leads to current page is expanded, as are tree branches around it.
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
            navtree.presentableSubnodes.each do |topnode|
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
            if topnode.presentableSubnodes.any? { |nav| nav.active?(currentPageUrl) }
                # We have active node at this level.
                # Therefore we want to list the whole level
                s << topnode.indent(level * 2 + 1)
                s << "<ul>\n"
                topnode.presentableSubnodes.each do |node|
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
                node = topnode.presentableSubnodes.find { |nav| nav.slug == currentPageSlugs[level] }
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
            topnode.presentableSubnodes.each do |node|
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

    ##
    # Children Liquid tag (list of child pages)
    #
    # This is a code for {% children %} liquid tag.
    # It lists child pages of a current page.
    class ChildrenTag < Liquid::Tag

        def initialize(tag_name, text, tokens)
          super
          parseParams(text)
        end

        def parseParams(text)
            @params = {}
            text.split(',').each do |piece|
                m = piece.match(/^\s*([\w\-_]+)\s*:\s*([\w\-_]+)\s*$/)
                if m
                    puts("Match! #{m}")
                    @params[m[1]] = m[2]
                else
                    raise ArgumentError, "Malformed parameters in children tag: #{piece}"
                end
            end
        end

        def render(context)
            navtree = context['site']['data']['nav']
            s = StringIO.new
            s << '<ul class="children">'
            children = navtree.children(context['page']['url'], @params)
            children.each do |child|
                s << '<li class="children-item">'
                child.append_label_link(s)
                s << '</li>'
            end
            s << '</ul>'
            s.string
        end
    end


    ##
    # Navigation tree node.
    #
    # Navigation tree is a hierarchy of Nav nodes.
    # Subnodes of each node are stored in subnodes field.
    # Each node is identified by "slug", which is one part of the URL hierarchy.
    class Nav
        attr_reader :subnodes, :slug
        attr_accessor :url, :title, :visibility, :display_order, :page

        def initialize(slug)
            @subnodes = []
            @slug = slug
            @url = nil
            @title = nil
        end

        def self.construct(site)
            navtree = Evolveum::Nav.new(nil)
            site.pages.each do |page|
                nav = navtree.index_page(page)
                #puts("  [C] #{nav.url}: #{nav.title}")
            end
            navtree.recomputeTree()
            return navtree
        end

        def recomputeTree()
            recomputeLevel(nil)
        end

        def recomputeLevel(parent)
            recomputeNode(parent)
            subnodes.each do |subnode|
                subnode.recomputeLevel(self)
            end
        end

        def recomputeNode(parent)
            if @visibility == nil
                if parent == nil
                    @visibility = 'visible'
                else
                    @visibility = parent.visibility
                end
            end
            if self.page != nil && self.page.data['effectiveVisibility'] == nil
                self.page.data['effectiveVisibility'] = @visibility
            end
#            puts("R: #{self.url} : #{self.visibility}")
        end

        def update(site)
            site.pages.each do |page|
                nav = index_page(page)
                #puts("  [U] #{nav.url}: #{nav.title}")
            end
        end

        def index_page(page)
            nav = index_path(page.url)
            nav.url = page.url
            nav.page = page
            nav.title = page.data['nav-title'] || page.data['title']
            if page.data['visibility'] != nil
                nav.visibility = page.data['visibility']
            end
            nav.display_order = page.data['display-order'].to_i
            if (nav.display_order == 0)
                nav.display_order = 100
            end
            nav
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

        def children(url, params = {})
            slugs = slugize(url)
            nav = self
            slugs.each do |slug|
                nav = nav.resolve(slug)
            end
            nav.presentableSubnodes(params)
        end

        def uninitializedStubs
            stubs = []
            collectUninitializedStubs(stubs, [])
            stubs
        end

        def collectUninitializedStubs(stubs, slugs)
            subnodes.each do |subnode|
                if (subnode.uninitializedStub?)
                    subnode.generate_url_if_needed(slugs)
                    stubs << subnode
                end
                subnode.collectUninitializedStubs(stubs, slugs + [ subnode.slug ])
            end
        end

        def generate_url_if_needed(slugs)
            if (@url == nil)
                if (slugs.empty?)
                    @url = '/' + slug
                else
                    @url = '/' + slugs.join('/') + '/' + slug
                end
            end
        end

        def uninitializedStub?
            @page == nil
        end

        def active?(currentPageUrl)
            @url != nil && @url == currentPageUrl
        end

        def visible?
            @visibility == 'visible'
        end

        def <=> other
            order = self.display_order <=> other.display_order
            if (order == 0)
                self.label.downcase <=> other.label.downcase
            else
                order
            end
        end

        # NOTE: this may not work well until we have all labels generated correctly
        def presentableSubnodes(params = {})
            subnodes.select{ |node| node.presentable?(params) }.sort
        end

        def presentable?(params = {})
            visibilityReq = params['visibility']
            if visibilityReq == nil
                return self.visible?
            elsif visibilityReq == 'all'
                return true
            else
                return self.visibility == visibilityReq
            end
        end

        def visibleSubnodes
            subnodes.select{ |node| node.visible? }
        end

        def processAllVisibleNavs(&block)
            processAllVisibleNavsLevel(self, &block)
        end

        def processAllVisibleNavsLevel(nav, &block)
            nav.visibleSubnodes.each do |subnav|
                block.call(subnav)
                processAllVisibleNavsLevel(subnav, &block)
            end
        end
    end

end

# Registering custom Liquid tags with Jekyll

Liquid::Template.register_tag('breadcrumbs', Evolveum::BreadcrumbsTag)
Liquid::Template.register_tag('navtree', Evolveum::NavtreeTag)
Liquid::Template.register_tag('children', Evolveum::ChildrenTag)

# Hooks to build the Nav tree.
#
# The tree is built in two passes.
#
# :post_read is first pass.
# At the time Jekyll knows about all the pages, but it does not have complete information.
# E.g. some page titles may be missing.
# However, we need to build basic Nav tree this early in the Jekyll build,
# because we need to generate stub pages.
# Therefore we need at least a basic Nav tree at the time when page generators are run.
#
# :pre_render is second run.
# Jekyll should have complete information about the pages now.
# We update the tree at this point, to have correct page titles later when the pages are rendered.

Jekyll::Hooks.register :site, :post_read do |site|
    #putsts "=========[ EVOLVEUM ]============== post_read #{site}"
    site.data['nav'] = Evolveum::Nav.construct(site)
end

Jekyll::Hooks.register :site, :pre_render do |site|
    #puts "=========[ EVOLVEUM ]============== pre_render #{site}"
    site.data['nav'].update(site)
end
