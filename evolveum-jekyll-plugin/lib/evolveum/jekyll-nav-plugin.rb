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

require_relative 'jekyll-versioning-plugin.rb'

module Evolveum

    ##
    # Page generator.
    # Generates stub pages for URLs that do not have their own pages.
    class StubGenerator < Jekyll::Generator
        priority :low

        def generate(site)
            @site = site
            site.data['nav'].uninitializedStubs.each do |nav|
                #puts "Generating stub #{nav.url}"
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
            nav.stub = true
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
            if Evolveum::Nav.section_mode?(context['site'])
                s << '<li class="breadcrumb-item"><a href="/">Home</a></li>'
            end
            breadcrumbs = navtree.breadcrumbs(context['page']['url'])
            breadcrumbs.each_with_index do |crumb, i|
                s << '<li class="breadcrumb-item">'
                if i == breadcrumbs.length - 1 && crumb.active?(context['page']['url'])
                    s << "<a href=\"#{crumb.url}\" aria-current=\"page\">"
                    s << crumb.label
                    s << "</a>"
                else
                    crumb.append_label_link(s)
                end
                s << '</li>'
            end
            s << '</ol>'
            s.string
        end
    end


    ##
    # Navigation tree Liquid tag.
    #
    # This is a code for {% navtree %} Liquid tag.
    # It renders navigation tree suitable for navigation panel.
    # This tree is "static", showing all items at levels where there is an active item.
    class NavtreeTag < Liquid::Tag

        def initialize(tag_name, text, tokens)
          super
          @text = text
        end

        def render(context)
            navtree = context['site']['data']['nav']
            currentPageUrl = context['page']['url']
            if Evolveum::Nav.section_mode?(context['site'])
                render_section(navtree, currentPageUrl)
            else
                render_legacy(navtree, currentPageUrl)
            end
        end

        def render_section(navtree, currentPageUrl)
            root = navtree.find(currentPageUrl)&.sidebar_root
            return render_top_level(navtree, currentPageUrl) if root == nil
            s = StringIO.new
            s << '<p class="ev-sidebar-home"><a href="/"><i class="fa-solid fa-house" aria-hidden="true"></i>Documentation home</a></p>'
            s << '<p class="ev-sidebar-title" id="navtree-title">'
            if root.active?(currentPageUrl)
                s << "<a href=\"#{root.url}\" aria-current=\"page\">#{root.label}</a>"
            else
                root.append_label_link(s)
            end
            s << "</p>\n"
            branch = StringIO.new
            unless root.active?(currentPageUrl)
                dive(branch, root, root.depth, currentPageUrl, navtree.slugize(currentPageUrl))
            end
            if branch.string.empty?
                append_subnodes(s, root, 0)
            else
                s << branch.string
            end
            s.string
        end

        def render_top_level(navtree, currentPageUrl)
            s = StringIO.new
            s << "<ul>\n"
            navtree.presentableSubnodes.each do |node|
                append_li_label_start(s, node, currentPageUrl, 1)
                s << "</li>\n"
            end
            s << "</ul>\n"
            s.string
        end

        def render_legacy(navtree, currentPageUrl)
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
                # Display just a single level and dive deeper.
                actNode = topnode.presentableSubnodes.find { |nav| nav.slug == currentPageSlugs[level] }
                if (actNode == nil) then return end
                s << topnode.indent(level * 2 + 1)
                s << "<ul>\n"
                topnode.presentableSubnodes.each do |node|
                    append_li_label_start(s, node, currentPageUrl, level * 2 + 2)
                    if node.slug == currentPageSlugs[level]
                        dive(s, node, level + 1, currentPageUrl, currentPageSlugs)
                    end
                    s << node.indent(level * 2 + 2)
                    s << "</li>\n"
                end
                s << topnode.indent(level * 2 + 1)
                s << "</ul>\n"

                # s << node.indent(level * 2 + 1)
                # s << "<ul>\n"
                # append_li_label_start(s, node, currentPageUrl, level * 2 + 2)
                # dive(s, node, level + 1, currentPageUrl, currentPageSlugs)
                # s << node.indent(level * 2 + 2)
                # s << "</li>\n"
                # s << node.indent(level * 2 + 1)
                # s << "</ul>\n"
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
            if (node.active?(currentPageUrl))
                s << '<li class="active">'
                s << "<a href=\"#{node.url}\" aria-current=\"page\">"
                s << node.label
                s << "</a>"
            else
                s << "<li>"
                node.append_label_link(s)
            end
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
                    @params[m[1]] = m[2]
                else
                    raise ArgumentError, "Malformed parameters in children tag: #{piece}"
                end
            end
        end

        def render(context)
            navtree = context['site']['data']['nav']
            children = navtree.children(context['page']['url'], @params)
            @s = StringIO.new
            if @params['style'] == 'table'
                renderTable(children)
            else
                renderList(children)
            end
            @s.string
        end

        def renderList(children)
            @s << '<ul class="children">'
            children.each do |child|
                @s << '<li class="children-item">'
                child.append_label_link(@s)
                @s << '</li>'
            end
            @s << '</ul>'
        end

        def renderTable(children)

            if @params['heading'] == nil
                heading = "Page"
            else
                heading = @params['heading']
            end

            @s << "<table class=\"tableblock frame-all grid-all fit-content\">\n"
            @s << "  <colgroup>\n"
            @s << "    <col>\n"
            @s << "    <col>\n"
            @s << "  </colgroup>\n"
            @s << "  <thead>\n"
            @s << "    <tr>\n"
            @s << "      <th class=\"tableblock halign-left valign-top\">"
            @s << heading
            @s << "</th>\n"
            @s << "      <th class=\"tableblock halign-left valign-top\">Description</th>\n"
            @s << "    </tr>\n"
            @s << "  </thead>\n"

            @s << "  <tbody>\n"

            children.each do |child|
                @s << "    <tr>\n"
                @s << "      <th class=\"tableblock halign-left valign-top\"><p class=\"tableblock\">"
                child.append_label_link(@s)
                @s << "</p></th>\n"
                @s << "      <td class=\"tableblock halign-left valign-top\"><p class=\"tableblock\">"
                @s << child&.page&.data&.[]('description')
                @s << "</p></td>\n"
                @s << "    </tr>\n"
            end

            @s << "  </tbody>\n"
            @s << "</table>\n"
        end
    end


    ##
    # Navigation tree node.
    #
    # Navigation tree is a hierarchy of Nav nodes.
    # Subnodes of each node are stored in subnodes field.
    # Each node is identified by "slug", which is one part of the URL hierarchy.
    class Nav
        attr_reader :subnodes, :slug, :parent
        attr_accessor :url, :title, :visibility, :display_order, :page, :alias, :stub

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
            navtree.recomputeTree(primary_urls(site))
            return navtree
        end

        def self.primary_urls(site)
            Array(site.data['navbar']).map { |item| item['url'] }.compact
        end

        def self.primary_url_for(url, primary_urls)
            normalized = with_trailing_slash(url)
            primary_urls
                .select { |candidate| normalized.start_with?(with_trailing_slash(candidate)) }
                .max_by { |candidate| with_trailing_slash(candidate).length }
        end

        def self.with_trailing_slash(url)
            url.end_with?('/') ? url : url + '/'
        end

        def self.report_stubs(site)
            navigation = site.config['navigation']
            return unless navigation.is_a?(Hash) && navigation['report-stubs'] == true
            site.data['nav'].stub_urls.each do |url|
                Jekyll.logger.warn("Navigation stub without an index page: #{url}")
            end
        end

        def stub_urls
            urls = []
            subnodes.each do |subnode|
                urls << subnode.url if subnode.stub
                urls.concat(subnode.stub_urls)
            end
            urls
        end

        def self.section_mode?(site)
            navigation = site.is_a?(Jekyll::Site) ? site.config['navigation'] : site['navigation']
            navigation.is_a?(Hash) && navigation['sidebar'] == 'section'
        end

        def recomputeTree(primary_urls = [])
            link_aliases
            recomputeLevel(nil)
            apply_section_data(primary_urls, {})
        end

        def apply_section_data(primary_urls, sidebar_roots)
            if @page != nil && !@alias
                root = section_root
                sidebar = root && (sidebar_roots.key?(root) ? sidebar_roots[root] : (sidebar_roots[root] = root.sidebar_candidate))
                @page.data['nav_section_url'] = sidebar&.url
                @page.data['nav_section_title'] = sidebar&.label
                @page.data['nav_primary_url'] = Nav.primary_url_for(@url, primary_urls)
            end
            subnodes.each { |subnode| subnode.apply_section_data(primary_urls, sidebar_roots) }
        end

        def depth
            @parent == nil ? 0 : @parent.depth + 1
        end

        def section_flag?
            [true, 'true'].include?(@page&.data&.[]('nav-section'))
        end

        def section_root
            return nil if @parent == nil
            node = self
            while node.depth > 1
                return node if node.section_flag?
                node = node.parent
            end
            node
        end

        def sidebar_candidate
            presentableSubnodes.empty? ? nil : self
        end

        def sidebar_root
            section_root&.sidebar_candidate
        end

        def find(url)
            node = self
            slugize(url).each do |slug|
                node = node.resolve(slug)
                return nil if node == nil
            end
            node
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
            if self&.page&.data&.[]('nav-title') == nil && parent&.page&.data&.[]('sub-nav-title-property') != nil
                propertyName = parent.page.data['sub-nav-title-property']
                propertyValue = self.page.data[propertyName]
                if propertyValue != nil
                    navTitle = ""
                    if parent&.page&.data&.[]('sub-nav-title-prefix') != nil
                        navTitle = parent&.page&.data&.[]('sub-nav-title-prefix')
                    end
                    navTitle += propertyValue.to_s
                    self.title = navTitle
                end
            end
#            puts("R: #{self.url} : #{self.visibility}")
        end

        def update(site)
            site.pages.each do |page|
                nav = index_page(page)
                #puts("  [U] #{nav.url}: #{nav.title}")
            end
            recomputeTree(Nav.primary_urls(site))
        end

        def index_page(page)
            nav = index_path(page.url)
            nav.url = page.url
            nav.page = page
            if (page.data['nav-title'] == "Configuration Reference")
                nav.title = page.data['midpointBranchDisplayName']
            else
                nav.title = page.data['nav-title'] || page.data['title']
            end

            if page.data['visibility'] != nil
                nav.visibility = page.data['visibility']
            end
            nav.display_order = page.data['display-order'].to_i
            if (nav.display_order == 0)
                nav.display_order = 100
            end
            if page.data['alias'] != nil
                @pending_aliases ||= []
                aliases = page.data['alias'].kind_of?(Array) ? page.data['alias'] : [page.data['alias']]
                aliases.each { |a| @pending_aliases << [a, page] }
            end
            nav
        end

        def link_aliases
            linked = (@pending_aliases || []).map { |aliasdef, page| index_alias(aliasdef, page) }.compact
            @pending_aliases = []
            linked.each do |alias_nav|
                own_nav = find(alias_nav.url)
                next if own_nav == nil || own_nav.section_root == alias_nav.parent.section_root
                warn_once("Alias of page #{alias_nav.url} is in another section, under #{alias_nav.parent.url || alias_nav.parent.slug}.")
            end
        end

        def warn_once(message)
            @warned ||= {}
            return if @warned[message]
            @warned[message] = true
            Jekyll.logger.warn(message)
        end

        def index_alias(aliasdef, page)
            parent_url = aliasdef['parent']
            if parent_url == nil
                Jekyll.logger.warn("No parent in alias specification in page #{page.url}, ignoring")
                return
            end
            if (parent_url.include?("/midpoint/reference/"))
                negativeLookAhead = VersionReader.get_config_value('negativeLookAhead')
                # if (page.data['midpointBranch'] == nil)
                #     Jekyll.logger.error("Page alias error: referencing reference documentation outside of reference documentation in page #{page.url}")
                # end
                if (parent_url.match?(negativeLookAhead))
                    if (page.data['midpointBranchSlug'] == nil)
                        parent_url = parent_url.gsub("/midpoint/reference/", "/midpoint/reference/#{VersionReader.get_config_value('defaultBranch')}/")
                    else
                        parent_url = parent_url.gsub("/midpoint/reference/", "/midpoint/reference/#{page.data['midpointBranchSlug']}/")
                    end
                else
                    Jekyll.logger.warn("Do not specify midpoint branch in PAGE ALIAS specification in page #{page.url}")
                end
            elsif (page.url.include?("/midpoint/reference/"))
                if (page.data['midpointBranch'] != VersionReader.get_config_value('defaultBranch'))
                    return
                end
                #Jekyll.logger.error("Page alias error: referencing non-reference documentation from reference documentation in page #{page.url}")
            end
            parent_nav = find(parent_url)
            if parent_nav == nil
                warn_once("Alias parent #{parent_url} does not exist, in alias specification in page #{page.url}. Ignoring.")
                return
            end
            slug = aliasdef['slug']
            if slug == nil
                slug = slugize(page.url).last
            end
            sub_nav = parent_nav.resolve(slug)
            if sub_nav != nil
                if sub_nav.url == page.url
                    # Already indexed
                    return
                end
                Jekyll.logger.warn("Alias slug #{slug} is already taken in #{parent_nav.url} by #{sub_nav.url}, in alias specification in page #{page.url}. Ignoring.")
                return
            end
            sub_nav = Evolveum::Nav.new(slug)
            parent_nav.add(sub_nav)
            sub_nav.url = page.url
            sub_nav.page = page
            sub_nav.alias = true
            sub_nav.title = aliasdef['title'] || page.data['nav-title'] || page.data['title']
            display_order = aliasdef['display-order'] || page.data['display-order']
            sub_nav.display_order = display_order.to_i
            if (sub_nav.display_order == 0)
                sub_nav.display_order = 100
            end
            sub_nav
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

        def resolvePath(path)
            node = self
            path.split('/').each do |slug|
                if slug != nil and !slug.strip.empty?
                    node = node.resolve(slug)
                    if !node
                        raise ArgumentError, "Cannot resolve #{path} on #{self}, last slug: #{slug}"
                    end
                end
            end
            return node
        end

        def add(subnode)
            subnode.parent = self
            @subnodes << subnode
        end

        attr_writer :parent
        protected :parent=

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

        # Probably not needed, page attributes seem to be HTML-encoded already
        #def label_encoded
        #    label.encode(:xml => :text)
        #end

        def append_label_link(s)
                if (@url != nil)
                    s << "<a href=\"#{@url}\">"
                end
                # Note: page title is HTML-encoded already
                s << label
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
            !@alias && @url != nil && @url == currentPageUrl
        end

        def visible?
            @visibility == 'visible'
        end

        def <=> other
            #puts("special first" + self.to_s + " other " + other.to_s)
            order = self.display_order <=> other.display_order
            if (order == 0)
                #puts("special secend" + self.label.downcase + " other " + other.label.downcase)
                self.label.downcase <=> other.label.downcase
            else
                order
            end
        end

        # NOTE: this may not work well until we have all labels generated correctly
        def presentableSubnodes(params = {})
            #puts("test  #{subnodes.join(', ')} ")
            #puts("test2 #{subnodes.select{ |node| node.presentable?(params) }.join(', ')}")
            #puts("test3 #{subnodes[0].display_order} #{subnodes[0].url}")
            begin
                subnodes.select{ |node| node.presentable?(params) }.sort{ |a,b| sortCompare(a,b) }
            rescue ArgumentError
                text = ""
                for i in subnodes.select{ |node| node.presentable?(params) } do
                    text = text + "#{i.url} #{i.label}"
                end
                raise ArgumentError, "FAILED AGAIN: #{text}"
            end

        end

        def sortCompare(a,b)
            sortBy = self&.page&.data&.[]('sub-sort-by')
            sortStrategy = self&.page&.data&.[]('sub-sort-strategy')
            sortDirection = self&.page&.data&.[]('sub-sort-direction')
            order = 0
            if sortBy != nil
                order = sortCompareValue(a&.page&.data&.[](sortBy), b&.page&.data&.[](sortBy), sortStrategy)
            end
            if order != 0
                return adjustSortOrder(order, sortDirection)
            end
            if a.display_order != nil && b.display_order != nil
                order = sortCompareValue(a.display_order, b.display_order)
                if order != 0
                    return adjustSortOrder(order, sortDirection)
                end
            end
            return adjustSortOrder(sortCompareValue(a.label.downcase, b.label.downcase), sortDirection)
        end

        def adjustSortOrder(order, direction)
            if direction == nil || direction == 'normal'
                return order
            else
                return -order
            end
        end

        def sortCompareValue(a, b, sortStrategy=nil)
            #puts("COMPARISON #{a} #{b}")
            if sortStrategy == nil
                return a <=> b
            end
            case sortStrategy
            when 'version'
                return sortCompareVersion(a, b)
            else
                raise ArgumentError, "Unknown sort strategy #{sortStrategy}"
            end
        end

        def sortCompareVersion(a,b)
#            puts("IIIIIIIII: #{a} <=> #{b}")
            if !a.is_a?(String)
                raise ArgumentError, "Cannot determine version from #{a.class}: #{a} in #{self.url}"
            end
            if !b.is_a?(String)
                raise ArgumentError, "Cannot determine version from #{b.class}: #{b} in #{self.url}"
            end
            al = a.split('.')
            bl = b.split('.')
            for i in 0..([al.length, bl.length].max - 1)
                if i >= al.length
                    return -1
                end
                if i >= bl.length
                    return 1
                end
                order = al[i].to_i <=> bl[i].to_i
 #               puts("IIIIIIIII: #{i}: #{al[i]} <=> #{bl[i]} -> #{order}")
                if order != 0
                    return order
                end
            end
            return 0
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

        def to_s()
            return "Nav(#{@url})"
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
    puts "=========[ EVOLVEUM nav ]============== post_read"
    site.data['nav'] = Evolveum::Nav.construct(site)
end

Jekyll::Hooks.register :site, :pre_render do |site|
    puts "=========[ EVOLVEUM nav ]============== pre_render"
    site.data['nav'].update(site)
    Evolveum::Nav.report_stubs(site)
end
