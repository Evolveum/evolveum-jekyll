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

    class XrefInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl

      named :xref
      name_positional_attributes 'linktext'

      def process(parent, target, attrs)
    #    puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXREF -------> Processing #{parent} #{targetFile} #{attrs}"

        targetPath = target
        fragmentSuffix = ""
        if target.include?('#')
            targetPath = target[0 .. target.rindex('#')-1]
            fragmentSuffix = target[target.rindex('#')..-1]
        end
        #puts "targetPath=#{targetPath}, fragment=#{fragmentSuffix}"

        targetPage = findPage(parent.document.attributes["docdir"], targetPath)

        if targetPage == nil
            sourceFile = parent.document.attributes["docfile"]
            Jekyll.logger.error("BROKEN LINK xref:#{target} in #{sourceFile}")
            return (create_anchor parent, attrs['linktext'], type: :link, target: "/broken_link/").convert
        end
        #puts pp parent.document
        if attrs['linktext'] == nil || attrs['linktext'].strip.empty?
            linktext = targetPage.data['title']
        else
            linktext = attrs['linktext']
        end
        targetUrl = targetPage.url
        parent.document.register :links, targetUrl
        (create_anchor parent, linktext, type: :link, target: (targetUrl + fragmentSuffix)).convert
      end

      def findPage(docdir, target)
        if target.end_with?("/")
            return findPageByUrl(docdir, target)
        else
            return findPageByFilePath(docdir, target)
        end
      end

      def findPageByFilePath(docdir, target)
        site = Jekyll.sites[0]
        filePathname = Pathname.new(target)

        if filePathname.absolute?
            relativeFilePath = target[1..-1]
        else
            relativeSourceDir = Pathname.new(docdir).relative_path_from(Pathname.new(site.source))
            relativeFilePath = (relativeSourceDir + filePathname).to_s
        end

    #    puts "relativeSourceDir=#{relativeSourceDir}, relativeFilePath=#{relativeFilePath}"
        return site.pages.find { |page| page.path == relativeFilePath }
      end

      def findPageByUrl(docdir, target)
        site = Jekyll.sites[0]
        targetPathname = Pathname.new(target)

        if targetPathname.absolute?
            url = target
        else
            relativeSourceDir = Pathname.new(docdir).relative_path_from(Pathname.new(site.source))
            url = "/" + (relativeSourceDir + targetPathname).to_s
        end

    #    puts "url=#{url}"
        return site.pages.find { |page| page.url == url }
      end

    end

    class WikiInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl

      named :wiki
      name_positional_attributes 'linktext'

      def process(parent, target, attrs)
        targetName = target
        fragmentSuffix = ""
        if target.include?('#')
            targetName = target[0 .. target.rindex('#')-1]
            fragmentSuffix = target[target.rindex('#')..-1]
        end
        #puts "targetName=#{targetName}, fragment=#{fragmentSuffix}"

        # TODO: look for pages that are already converted: search pages for wiki-name page attribute

        if attrs['linktext'] == nil || attrs['linktext'].strip.empty?
            # TODO: urldecode
            linktext = targetName
        else
            linktext = attrs['linktext']
        end
        targetUrl = "https://wiki.evolveum.com/display/midPoint/#{target}"

        puts "WWWIKI: #{target} -> #{targetUrl}"

        parent.document.register :links, targetUrl
        (create_anchor parent, linktext, type: :link, target: (targetUrl)).convert
      end

    end

    class BugInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
      use_dsl

      named :bug
      name_positional_attributes 'linktext'

      def process(parent, target, attrs)

        if attrs['linktext'] == nil || attrs['linktext'].strip.empty?
            linktext = target
        else
            linktext = attrs['linktext']
        end
        targetUrl = "https://jira.evolveum.com/browse/#{target}"

        puts "BBBUG: #{target} -> #{targetUrl}"

        parent.document.register :links, targetUrl
        (create_anchor parent, linktext, type: :link, target: (targetUrl)).convert
      end

    end

end

Asciidoctor::Extensions.register do
  inline_macro Evolveum::XrefInlineMacro
  inline_macro Evolveum::WikiInlineMacro
  inline_macro Evolveum::BugInlineMacro
end
