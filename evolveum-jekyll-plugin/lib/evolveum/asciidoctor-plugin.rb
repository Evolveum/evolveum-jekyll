# (C) 2020-2021 Evolveum
#
# Evolveum AsciiDoctor Plugin for Jekyll sites
#
# This is a plugin that overrides the xref: in-line asciidoc macro.
# It translates filename to URL using pages in Jekyll site.
#

require 'asciidoctor'
require 'asciidoctor/extensions'
require 'pathname'
require 'pp'

module Evolveum

    class JekyllInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl

      name_positional_attributes 'linktext'

      def parseFraqment(target)
        targetPath = target
        fragmentSuffix = ""
        if target.include?('#')
            targetPath = target[0 .. target.rindex('#')-1]
            fragmentSuffix = target[target.rindex('#')..-1]
        end
        return targetPath, fragmentSuffix
      end

      def createLink(targetUrl, parent, attrs, defaultLinkText)
        if attrs['linktext'] == nil || attrs['linktext'].strip.empty?
            linktext = defaultLinkText
        else
            linktext = attrs['linktext']
        end
        parent.document.register :links, targetUrl
        (create_anchor parent, linktext, type: :link, target: targetUrl).convert
      end

      # target can be URL or file path
      def findPageByTarget(docdir, target)
        if target.end_with?("/")
            return findPageByUrl(docdir, target)
        elsif target.match(/\/[^\/\.]+$/)
            # URL without trailing slash
            return findPageByUrl(docdir, target + "/")
        else
            return findPageByFilePath(docdir, target)
        end
      end

      def findPageByFilePath(docdir, target)
        site = getJekyllSite()
        filePathname = Pathname.new(target)

        if filePathname.absolute?
            relativeFilePath = target[1..-1]
        else
            relativeSourceDir = Pathname.new(docdir).relative_path_from(Pathname.new(site.source))
            relativeFilePath = (relativeSourceDir + filePathname).to_s
        end

    #    puts "relativeSourceDir=#{relativeSourceDir}, relativeFilePath=#{relativeFilePath}"
        return findPage { |page| page.path == relativeFilePath }
      end

      def findPageByUrl(docdir, target)
        site = getJekyllSite()
        targetPathname = Pathname.new(target)

        if targetPathname.absolute?
            url = target
        else
            relativeSourceDir = Pathname.new(docdir).relative_path_from(Pathname.new(site.source))
            url = "/" + (relativeSourceDir + targetPathname).to_s
        end

        page = findPage { |page| page.url == url }
        #puts "FFF: #{url} -> #{page&.url}"
        return page
      end

      def getJekyllSite()
        return Jekyll.sites[0]
      end

      def findPage
        return getJekyllSite().pages.find { |page| yield page }
      end

    end


    class XrefInlineMacro < JekyllInlineMacro
      use_dsl

      named :xref
      name_positional_attributes 'linktext'

      def process(parent, target, attrs)
    #    puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXREF -------> Processing #{parent} #{targetFile} #{attrs}"

        targetPath, fragmentSuffix = parseFraqment(target)
        #puts "targetPath=#{targetPath}, fragment=#{fragmentSuffix}"

        targetPage = findPageByTarget(parent.document.attributes["docdir"], targetPath)
#        puts("XXXREF found page #{targetPage}")

        if targetPage == nil
            sourceFile = parent.document.attributes["docfile"]
            ignore = parent.document.attributes["ignore-broken-links"]
            if ignore == nil
                Jekyll.logger.error("BROKEN LINK xref:#{target} in #{sourceFile}")
            else
                Jekyll.logger.debug("Ignoring broken link xref:#{target} in #{sourceFile}")
            end
            return (create_anchor parent, attrs['linktext'], type: :link, target: "/broken_link/").convert
        end

        createLink(targetPage.url, parent, attrs, targetPage.data['title'])
      end
    end


    class WikiInlineMacro < JekyllInlineMacro
      use_dsl

      named :wiki
      name_positional_attributes 'linktext'

      def process(parent, target, attrs)
        targetName, fragmentSuffix = parseFraqment(target)
        wikiName = targetName.gsub(/\+/, ' ')

        page = findMigratedPage(wikiName)
        if page != nil
#            puts("WWWIKI-------> found page #{page.url}")
            targetUrl = page.url
        else
 #           puts("WWWIKI no page for name #{wikiName}")
            targetUrl = "https://wiki.evolveum.com/display/midPoint/#{target}"
        end

 #       puts "WWWIKI: #{target} -> #{targetUrl}"

        createLink(targetUrl, parent, attrs, wikiName)
      end

      def findMigratedPage(wikiName)
        findPage { |page| page.data['wiki-name'] == wikiName }
      end

    end

    class BugInlineMacro < JekyllInlineMacro
      use_dsl

      named :bug
      name_positional_attributes 'linktext'

      def process(parent, target, attrs)

        targetUrl = "https://jira.evolveum.com/browse/#{target}"
#        puts "BBBUG: #{target} -> #{targetUrl}"
        createLink(targetUrl, parent, attrs, target)
      end

    end

end

Asciidoctor::Extensions.register do
  inline_macro Evolveum::XrefInlineMacro
  inline_macro Evolveum::WikiInlineMacro
  inline_macro Evolveum::BugInlineMacro
end
