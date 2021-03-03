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

      def parseFragment(target)
        targetPath = target
        fragmentSuffix = ""
        if target.include?('#')
            targetPath = target[0 .. target.rindex('#')-1]
            fragmentSuffix = target[target.rindex('#')..-1]
        end
        return targetPath, fragmentSuffix
      end

      def addFragmentSuffix(path, fragmentSuffix)
        if fragmentSuffix != nil && !fragmentSuffix.empty?
          return path + fragmentSuffix
        else
          return path
        end
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
        relativeFilePath = toRelativePathname(docdir, target)
    #    puts "relativeSourceDir=#{relativeSourceDir}, relativeFilePath=#{relativeFilePath}"
        page = findPage { |page| page.path == relativeFilePath }
        #puts "FFF:FILE: #{relativeFilePath} -> #{page&.url}"
        return page
      end
      
      def toRelativePathname(docdir, target)
        targetPathname = Pathname.new(target)
        if targetPathname.absolute?
            return target[1..-1]
        else
            relativeSourceDir = Pathname.new(docdir).relative_path_from(Pathname.new(jekyllSite().source))
            return (relativeSourceDir + targetPathname).to_s
        end
      end


      def findPageByUrl(docdir, target)
        site = jekyllSite()
        targetPathname = Pathname.new(target)

        if targetPathname.absolute?
            url = target
        else
            relativeSourceDir = Pathname.new(docdir).relative_path_from(Pathname.new(site.source))
            url = "/" + (relativeSourceDir + targetPathname).to_s
        end

        page = findPage { |page| page.url == url }
        #puts "FFF:URL: #{url} -> #{page&.url}"
        return page
      end

      def findFile(docdir, target)
          relativeFilePathname = toRelativePathname(docdir, target)
          absoluteFilePathname = Pathname.new(jekyllSite().source) + relativeFilePathname
          #puts "FFF:FILE: #{target} -> #{absoluteFilePathname}"
          return absoluteFilePathname
      end


      def jekyllSite()
        return Jekyll.sites[0]
      end

      def findPage
        return jekyllSite().pages.find { |page| yield page }
      end

    end

    class JekyllBlockMacro < Asciidoctor::Extensions::BlockMacroProcessor
        use_dsl

    end

    class XrefInlineMacro < JekyllInlineMacro
      use_dsl

      named :xref
      name_positional_attributes 'linktext'

      def process(parent, target, attrs)
    #    puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXREF -------> Processing #{parent} #{targetFile} #{attrs}"

        targetPath, fragmentSuffix = parseFragment(target)
        #puts "targetPath=#{targetPath}, fragment=#{fragmentSuffix}"

        targetPage = findPageByTarget(parent.document.attributes["docdir"], targetPath)
#        puts("XXXREF found page #{targetPage}")

        if targetPage == nil
            # No page. But there still may be a plain file (e.g. a PDF file)
            absoluteFilePathname = findFile(parent.document.attributes["docdir"], targetPath)
            if absoluteFilePathname.exist?
                createLink(target, parent, attrs, targetPath)
            else
                sourceFile = parent.document.attributes["docfile"]
                ignore = parent.document.attributes["ignore-broken-links"]
                if ignore == nil
                    Jekyll.logger.error("BROKEN LINK xref:#{target} in #{sourceFile}")
                else
                    Jekyll.logger.debug("Ignoring broken link xref:#{target} in #{sourceFile}")
                end
                return (create_anchor parent, attrs['linktext'], type: :link, target: "/broken_link/").convert
            end
        else
            createLink(addFragmentSuffix(targetPage.url,fragmentSuffix), parent, attrs, targetPage.data['title'])
        end
      end
      
    end


    class WikiInlineMacro < JekyllInlineMacro
      use_dsl

      named :wiki
      name_positional_attributes 'linktext'

      def process(parent, target, attrs)
        targetName, fragmentSuffix = parseFragment(target)
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

    class JekyllTreeprocessor < Asciidoctor::Extensions::Treeprocessor

        def jekyllSite()
            return Jekyll.sites[0]
        end

        def findPage
            return jekyllSite().pages.find { |page| yield page }
        end

        def findCurrentPage(document)
            docfile = document.attr("docfile")
            siteDirPathname = Pathname.new(jekyllSite.source)
            relativeDocfilePath = Pathname.new(docfile).relative_path_from(Pathname.new(jekyllSite.source)).to_s
            page = findPage { |page| page.path == relativeDocfilePath }
            #puts("RRRRRRRRRRRRRRRRRRR: #{relativeDocfilePath} -> #{page&.url}")
            return page
        end

        def removeLeadingSlash(path)
            if path.start_with?('/')
                return path[1..-1]
            else
                return path
            end
        end
    end

    class ImagePathTreeprocessor < JekyllTreeprocessor
        def process(document)
            currentPage = findCurrentPage(document)
            document.find_by(context: :image).each do |image|
                target = image.attr('target')
                image.set_attr("target",fixImagePath(target, document, currentPage))
          end
        end

        def fixImagePath(target, document, currentPage)
            #puts("IMAGEFIX: #{target}, #{currentPage.url}")
            targetPathname = Pathname.new(target)
            if targetPathname.absolute?
                # No need to fix, absolute URLs are fine
                #puts("IMAGEFIX: #{target} (no change, absolute)")
                return target
            end
            urlizedPathname = Pathname.new(jekyllSite.source) + Pathname.new(removeLeadingSlash(currentPage.url))
            targetFilePathname =  urlizedPathname + targetPathname
            #puts("IMAGEFIX: #{target} --> #{targetFilePathname} = #{targetFilePathname.exist?}")
            if targetFilePathname.exist?
                # The target points to an existing file, this is probably OK
                #puts("IMAGEFIX: #{target} (no change, existing file)")
                return target
            end

            #puts("IMAGEFIX: NOT FOUND #{target} --> #{targetFilePathname}")

            # The author probably specified file path relative to the source file
            # But we need path relative to the target URL
            diff = Pathname.new(document.attr('docdir')).relative_path_from(urlizedPathname)
            #puts("IMAGEFIX: DIFF #{diff}")

            diffedTargetPathname = (diff + targetPathname)

            diffedTargetFilePathname =  urlizedPathname + diffedTargetPathname

            if !diffedTargetFilePathname.exist?
                sourceFile = document.attr("docfile")
                ignore = document.attr("ignore-broken-links")
                if ignore == nil
                    Jekyll.logger.error("BROKEN IMAGE LINK image::#{target} in #{sourceFile}")
                else
                    Jekyll.logger.debug("Ignoring broken image link image:#{target} in #{sourceFile}")
                end
            end

            #puts("IMAGEFIX: #{target} --> #{diffedTarget} (not found)")

            return diffedTargetPathname.to_s
       end

    end

end

Asciidoctor::Extensions.register do
  inline_macro Evolveum::XrefInlineMacro
  inline_macro Evolveum::WikiInlineMacro
  inline_macro Evolveum::BugInlineMacro
  treeprocessor Evolveum::ImagePathTreeprocessor
end
