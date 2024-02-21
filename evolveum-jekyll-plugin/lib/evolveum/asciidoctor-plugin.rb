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
require_relative 'jekyll-versioning-plugin.rb' # We need readVersions method for checking if xfer path includes exact midpoint version

module Evolveum

    module JekyllUtilMixin

        def jekyllSite()
            return Jekyll.sites[0]
        end

        def jekyllData(dataName)
            return jekyllSite().data[dataName]
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

        # target can be URL or file path
        def findPageByTarget(document, target)
            if target.end_with?("/")
                return findPageByUrl(document, target)
            elsif target.match(/\/[^\/\.]+$/)
                # URL without trailing slash
                return findPageByUrl(document, target + "/")
            else
                return findPageByFilePath(document, target)
            end
        end

        def findPageByFilePath(document, target)
            docdir = document.attributes["docdir"]
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

        def findPageByUrl(document, target)
            docdir = document.attributes["docdir"]
            site = jekyllSite()
            targetPathname = Pathname.new(target)

            if targetPathname.absolute?
                url = target
                page = findPage { |page| page.url == url }
            else
                # Try whether the link is relative to source document path
                relativeSourceDir = Pathname.new(docdir).relative_path_from(Pathname.new(site.source))
                url = "/" + (relativeSourceDir + targetPathname).to_s
                page = findPage { |page| page.url == url }
                if page == nil
                    # maybe the author meant the link as relative to URL of source document, not filesystem path
                    #puts "Cannot find page by filesystem-based relative link, trying URL-based relative link (#{targetPathname})"
                    currentPage = findCurrentPage(document)
                    currentPageUrlPathname = Pathname.new(currentPage.url)
                    url = (currentPageUrlPathname + targetPathname).to_s
                    page = findPage { |page| page.url == url }
                end
            end

            #puts "FFF:URL: #{url} -> #{page&.url}"
            return page
        end

        def findFileByTarget(document, target)
            currentPage = findCurrentPage(document)
            if target.start_with?("/")
                # All is clear, this is absolute URL from the site root
                absoluteFilePathname = Pathname.new(jekyllSite().source) + Pathname.new(target[1..-1])
                Jekyll.logger.debug("File xref trying absolute: #{target} -> #{absoluteFilePathname}")
                if absoluteFilePathname.exist?
                    return target
                else
                    return nil
                end
            end

            # Try if target path is relative to source file first
            docdir = document.attributes["docdir"]
            relativeFilePathname = toRelativePathname(docdir, target)
            absoluteFilePathname = Pathname.new(jekyllSite().source) + relativeFilePathname
            Jekyll.logger.debug("File xref trying source relative: #{target} -> #{absoluteFilePathname}")
            if absoluteFilePathname.exist?
                # target path is relative to source path, but we need to make it relative to page URL now
                # TODO: should we make it relative to page URL?
                return target
            else
                # target path is not relative to source file, try whether it is relative to current page URL
                currentPageUrlPathname = Pathname.new(currentPage.url[1..-1])
                relativeFilePathname = Pathname.new(target)
                absoluteFilePathname = Pathname.new(jekyllSite().source) + currentPageUrlPathname + relativeFilePathname
                Jekyll.logger.debug("File xref trying url relative: #{target} -> #{absoluteFilePathname}")
                if absoluteFilePathname.exist?
                    return target
                else
                    return nil
                end
            end
        end

        def findFile(docdir, target)
            relativeFilePathname = toRelativePathname(docdir, target)
            absoluteFilePathname = Pathname.new(jekyllSite().source) + relativeFilePathname
            #puts "FFF:FILE: #{target} -> #{absoluteFilePathname}"
            return absoluteFilePathname
        end

    end

    class JekyllInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
        include JekyllUtilMixin
        use_dsl

        name_positional_attributes 'linktext'

        def parseFragment(target)
            targetPath = target
            fragmentSuffix = ""
            if target.start_with?('#')
                targetPath = nil
                fragmentSuffix = target
            elsif target.include?('#')
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

        def createLink(targetUrl, parent, attrs, defaultLinkText, role = nil)
            if attrs['linktext'] == nil || attrs['linktext'].strip.empty?
                linktext = defaultLinkText
            else
                linktext = attrs['linktext']
            end
            parent.document.register :links, targetUrl
            node = (create_anchor parent, linktext, type: :link, target: targetUrl)
            if role != nil
                node.add_role(role)
            end
            node.convert
        end

        # methods used in xref and xrefv macros

        def ignoreLinkBreak?(parent, targetPath)
            pageIgnore = parent.document.attributes["ignore-broken-links"]
            if pageIgnore != nil
                return true
            end
            ignoredPrefixes = parent.document.attributes["xref-ignored-prefixes"]
            if ignoredPrefixes == nil
                return false
            end
            return ignoredPrefixes.any? { |prefix|  targetPath.start_with?(prefix) }
        end

        def processXRefLink(parent, target, attrs)
        #    puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXREF -------> Processing #{parent} #{targetFile} #{attrs}"

            targetPath, fragmentSuffix = parseFragment(target)
            sourceFile = parent.document.attributes["docfile"]
            # puts "targetPath=#{targetPath}, fragment=#{fragmentSuffix}"

            if targetPath == nil
                # document-local link, use as is
                return (create_anchor parent, attrs['linktext'], type: :link, target: target).convert
            end

            targetPage = findPageByTarget(parent.document, targetPath)
            #puts("DEBUG XREF #{targetPath} -> found page #{targetPage&.url} in #{sourceFile}")

            # Checking if target includes specific midpoint versions


            if targetPage == nil
                # No page. But there still may be a plain file (e.g. a PDF file)
                fileUrl = findFileByTarget(parent.document, targetPath)
                output = ""
                if fileUrl == nil
                    if ignoreLinkBreak?(parent, targetPath)
                        Jekyll.logger.debug("Ignoring broken link xref:#{target} in #{sourceFile}")
                    else
                        output = `grep -rl ":page-moved-from: #{target}" /docs/`
                        if (output != nil && output != "")
                            Jekyll.logger.warn("DEPRECATED LINK xref:#{target} in #{sourceFile}")
                        else
                            escaped_target = Regexp.escape("\nmoved-from: #{target}\n")
                            output = `grep -rl #{escaped_target} /docs/`
                            if (output != nil && output != "")
                                Jekyll.logger.warn("DEPRECATED LINK xref:#{target} in #{sourceFile}")
                            else
                                targetArr = target.split("/").drop(1)
                                matched = false
                                targetArr.each_with_index do |version, index|
                                    partTargetArr = targetArr[...index+1]
                                    escaped_target = Regexp.escape("#{partTargetArr.join("/")}/\*")
                                    output = `grep -rl ":page-moved-from: /#{escaped_target}" /docs/`
                                    if (output != nil && output != "")
                                        movedPart = `sed -n -e '/^:page-moved-from: /p' #{output.split("\n")[0]}`
                                        movedPart = movedPart.gsub(":page-moved-from:", "")
                                        movedPart = movedPart.gsub("*", "")
                                        movedPart = movedPart.gsub(/\n/, "")
                                        targetPath = movedPart + targetArr[index+1...].join("/") + "/"
                                        targetPage = findPageByTarget(parent.document, targetPath)
                                        if targetPage == nil
                                            Jekyll.logger.error("BROKEN LINK xref:#{target} in #{sourceFile}")
                                        else
                                            Jekyll.logger.warn("DEPRECATED LINK xref:#{target} in #{sourceFile}")
                                        end
                                        matched = true
                                        break
                                    end
                                end
                                if (!matched)
                                    Jekyll.logger.error("BROKEN LINK xref:#{target} in #{sourceFile}")
                                end
                            end
                        end
                    end
                    # Leave the target of broken link untouched. Redirects may still be able to handle it.
                    return (create_anchor parent, attrs['linktext'], type: :link, target: target).convert
                else
                    createLink(target, parent, attrs, fileUrl)
                end
            else
                createLink(addFragmentSuffix(targetPage.url,fragmentSuffix), parent, attrs, targetPage.data['title'])
            end
        end


    end

    class JekyllBlockMacro < Asciidoctor::Extensions::BlockMacroProcessor
        include JekyllUtilMixin
        use_dsl

    end

    class XrefInlineMacro < JekyllInlineMacro
      use_dsl

      named :xref
      name_positional_attributes 'linktext'

      # Check if there is an sprecific midpoint version included in link
      def process(parent, target, attrs)
        verArr = readVersions()
        versions = verArr[0]
        sourceFile = parent.document.attributes["docfile"]
        versions.each do |version|
            versionWithoutDocs = version.gsub("docs/","")
            if target.include?("/" + versionWithoutDocs + "/")
                Jekyll.logger.warn("Specific midpoint version included in link xref:#{target} in #{sourceFile}")
                puts("Specific version included")
            end
        end
        processXRefLink(parent, target, attrs)
      end
    end

    class XrefVInlineMacro < JekyllInlineMacro
        use_dsl

        named :xrefv
        name_positional_attributes 'linktext'

        def process(parent, target, attrs)
            processXRefLink(parent, target, attrs)
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
            sourceFile = parent.document.attributes["docfile"]
            Jekyll.logger.error("BROKEN WIKI LINK wiki:#{target} in #{sourceFile}")
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

    class GlossrefInlineMacro < JekyllInlineMacro
      use_dsl

      named :glossref
      name_positional_attributes 'linktext'

      def process(parent, target, attrs)

        glossentry = findGlossaryEntry(target)
        if glossentry == nil
            sourceFile = parent.document.attributes["docfile"]
            Jekyll.logger.error("BROKEN GLOSSARY ENTRY #{target} in #{sourceFile}")
            defaultLabel = target
        else
            defaultLabel = glossentry['term']
        end
        targetUrl = "/glossary/##{target}"
#        puts "GLOSSREF: #{target} -> #{targetUrl}"

        createLink(targetUrl, parent, attrs, defaultLabel, "glossref")
      end

      def findGlossaryEntry(entry_id)
        glossary = jekyllData('glossary')
        glossentry = glossary.detect {|e| e['id'] == entry_id }
#        puts "GLOSSREF:entry: #{glossentry}"
        return glossentry
      end

    end

    class JekyllTreeprocessor < Asciidoctor::Extensions::Treeprocessor
        include JekyllUtilMixin

    end

    class ImagePathTreeprocessor < JekyllTreeprocessor
        def process(document)

            # ATTENTION! Use this if there is an error in index.adoc file, and you do not know which one it is
            #Jekyll.logger.info("Processing document #{document.attr("docfile")}")

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
  inline_macro Evolveum::XrefVInlineMacro
  inline_macro Evolveum::WikiInlineMacro
  inline_macro Evolveum::BugInlineMacro
  inline_macro Evolveum::GlossrefInlineMacro
  treeprocessor Evolveum::ImagePathTreeprocessor
end
