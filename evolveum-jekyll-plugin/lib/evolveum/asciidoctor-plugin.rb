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
require 'open3'
require 'cgi'
require_relative 'jekyll-versioning-plugin.rb' # We need readVersions method for checking if xfer path includes exact midpoint version
require_relative 'jekyll-redirect-plugin.rb'

module Evolveum

    module JekyllUtilMixin

        def jekyllSite()
            return Jekyll.sites[0]
        end

        def docsDir()
            return (jekyllSite().config['docs']['docsPath'] + jekyllSite().config['docs']['docsDirName'])
        end

        def samplesDir()
            return (jekyllSite().config['docs']['midpointSamplesPath'] + jekyllSite().config['docs']['midpointSamplesDirName'])
        end

        def midpointVersionsDir(branch)
            return (jekyllSite().config['docs']['midpointVersionsPath'] + jekyllSite().config['docs']['midpointVersionsPrefix'] + branch.gsub("docs/",""))
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

            if targetPath == nil
                # document-local link, use as is
                return (create_anchor parent, attrs['linktext'], type: :link, target: target).convert
            end

            targetPath = CGI.unescapeHTML(targetPath)

            targetPage = findPageByTarget(parent.document, targetPath)

            # Checking if target includes specific midpoint versions


            if targetPage == nil
                # No page. But there still may be a plain file (e.g. a PDF file)
                fileUrl = findFileByTarget(parent.document, targetPath)
                output = []
                if fileUrl == nil
                    ignore = false
                    if ignoreLinkBreak?(parent, targetPath)
                        Jekyll.logger.debug("Ignoring broken link xref:#{target} in #{sourceFile}")
                        ignore = true
                    else
                        #Jekyll.logger.warn(Evolveum.getPageRedirects().to_s)
                        matches = false
                        Evolveum.getPageRedirects().each do |redirect|
                            if target.match?(redirect['pattern'])
                                matches = true
                                Jekyll.logger.warn(redirect['pattern'].to_s + " test " + target)
                                break
                            end
                        end

                        if matches
                            Jekyll.logger.warn("DEPRECATED LINK xref:#{target} in #{sourceFile}")
                        else
                            Jekyll.logger.error("BROKEN LINK xref:#{target} in #{sourceFile}")
                        end
                    end
                    # Leave the target of broken link untouched. Redirects may still be able to handle it.
                    if attrs['linktext'] == nil || attrs['linktext'].strip.empty?
                        if (!ignore)
                            Jekyll.logger.error("NO linktext ATTRIBUTE IN BROKEN LINK xref:#{target} in #{sourceFile}")
                        end
                        return (create_anchor parent, "link", type: :link, target: target).convert
                    else
                        return (create_anchor parent, attrs['linktext'], type: :link, target: target).convert
                    end
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

        def processCodeInclude(parent, target, attrs, filePath, branch)
            if (target != nil && File.exist?(filePath))
                fileExt = File.extname(target)[1..-1]
                startLine = 1
                endLine = -1
                includeCopyrightNotice = false
                includeOnlyTag = nil
                includeOnlyTagLevel = 0
                includeOnlyTagOrder = 0
                startPattern = nil
                endPattern = nil
                if (attrs['lines'] != nil)
                    splittedAttrs = attrs['lines'].split("..")
                    if (splittedAttrs.length == 2)
                        startLine = splittedAttrs[0].to_i
                        endLine = splittedAttrs[1].to_i
                    elsif branch != nil
                        Jekyll.logger.error("BROKEN MIDPOINT REFERENCE - INCORRECT LINE SELECTION FORMAT midpointRef:#{target}, branch:#{branch} in #{parent.document.attributes["docfile"]}")
                    else
                        Jekyll.logger.error("BROKEN SAMPLE REFERENCE - INCORRECT LINE SELECTION FORMAT sampleRef:#{target} in #{parent.document.attributes["docfile"]}")
                    end
                end

                #puts "STARTLINE: #{startLine}" if attrs['lines']
                #puts "ENDLINE: #{endLine}" if attrs['lines']
                #puts attrs['includeCopyrightNotice'] ? "INCLUDE_COPYRIGHT_NOTICE: #{attrs['includeCopyrightNotice']}" : "false - default"

                if attrs['includeCopyrightNotice'].to_s.downcase == 'true'
                  includeCopyrightNotice = true
                end

                if (attrs['includeOnlyTag'] != nil)
                  includeOnlyTag = attrs['includeOnlyTag']
                end

                if (attrs['includeOnlyTagLevel'] != nil)
                  includeOnlyTagLevel = attrs['includeOnlyTagLevel'].to_i
                end

                if (attrs['includeOnlyTagOrder'] != nil)
                  includeOnlyTagOrder = attrs['includeOnlyTagOrder'].to_i
                end

                #Jekyll.logger.warn("STARTPATTERN: #{attrs['startPattern']}") if attrs['startPattern']
                #Jekyll.logger.warn("ENDPATTERN: #{attrs['endPattern']}") if attrs['endPattern']

                if (attrs['startPattern'] != nil && attrs['endPattern'] == nil)
                  Jekyll.logger.error("BROKEN SAMPLE REFERENCE - INCORRECT PATTERN SELECTION FORMAT sampleRef:#{target} in #{parent.document.attributes["docfile"]} - startPattern is set but endPattern is not")
                  create_pass_block parent, " ", attrs, subs: nil
                  return
                elsif (attrs['startPattern'] == nil && attrs['endPattern'] != nil)
                  Jekyll.logger.error("BROKEN SAMPLE REFERENCE - INCORRECT PATTERN SELECTION FORMAT sampleRef:#{target} in #{parent.document.attributes["docfile"]} - endPattern is set but startPattern is not")
                  create_pass_block parent, " ", attrs, subs: nil
                  return
                elsif (attrs['startPattern'] != nil && attrs['endPattern'] != nil && !includeCopyrightNotice)
                  # When strartPattern and endPattern are set, we do not want to unnecessarily find the copyright, it would be filtered out be default
                  includeCopyrightNotice = true
                elsif (attrs['startPattern'] != nil && attrs['endPattern'] != nil && (attrs['includeOnlyTag'] != nil))
                  Jekyll.logger.error("BROKEN SAMPLE REFERENCE - INCOMPATIBLE ATTRS sampleRef:#{target} in #{parent.document.attributes["docfile"]} - startPattern and endPattern are set, but includeOnlyTag is also set, for now using startPattern and endPattern")
                  includeOnlyTag = nil
                elsif ((attrs['startPattern'] != nil || attrs['endPattern'] != nil) && (attrs['includeOnlyTag'] != nil))
                  Jekyll.logger.error("BROKEN SAMPLE REFERENCE - INCOMPATIBLE ATTRS sampleRef:#{target} in #{parent.document.attributes["docfile"]} - startPattern or endPattern are set, but includeOnlyTag is also set, did not recover")
                  create_pass_block parent, " ", attrs, subs: nil
                  return
                elsif (includeOnlyTag != nil && !includeCopyrightNotice)
                  # Removing copyright notice is unnecessary when we are including only specific tag
                  includeCopyrightNotice = true
                end
                if (attrs['startPattern'] != nil && attrs['endPattern'] != nil)
                  begin
                    startPattern = Regexp.new(attrs['startPattern'])
                    endPattern = Regexp.new(attrs['endPattern'])
                  rescue RegexpError => e
                    Jekyll.logger.error("BROKEN SAMPLE REFERENCE - INCORRECT PATTERN SELECTION FORMAT sampleRef:#{target} in #{parent.document.attributes["docfile"]} - invalid regular expression")
                    create_pass_block parent, " ", attrs, subs: nil
                    return
                  end
                end

                lines = []
                tempLines = []

                current_line = 0
                current_temp_line = 0

                if ((fileExt == "xml" || fileExt == "xsd") && startLine < 2 && !includeCopyrightNotice)
                  content = File.read(filePath)
                  originalLines = content.lines.size
                  # Remove leading whitespace (spaces, tabs, newlines)
                  trimmed = content.lstrip
                  trimmed = trimmed.sub(/\A<\?xml\s+.*?\?>\s*/, "")
                  #Jekyll.logger.warn("REMOVING XML DECLARATION - sampleRef:#{target} in #{parent.document.attributes["docfile"]} - removing XML declaration, #{trimmed.lines.first}")
                  trimmed = trimmed.lstrip
                  trimmed = trimmed.sub(/^\s*<!--\s*used\s+in\s+docs\s*-->\s*(\r?\n|\r|\n)?/, "")
                  #Jekyll.logger.warn("REMOVING COMMENT - sampleRef:#{target} in #{parent.document.attributes["docfile"]} - removing comment, #{trimmed.lines.first}")
                  trimmed = trimmed.lstrip
                  afterLines = trimmed.lines.size
                  current_temp_line = originalLines - afterLines
                  #Jekyll.logger.warn("REMOVED LINES - sampleRef:#{target} in #{parent.document.attributes["docfile"]} - removed #{current_temp_line} lines")
                  found = false
                  endedPrematurely = false
                  if trimmed.start_with?('<!--')
                    trimmed.each_line do |line|
                      current_temp_line += 1
                      if current_temp_line == endLine
                        endedPrematurely = true
                        break
                      end
                      if (line.include?('Copyright (c)') || line.include?('Copyright (C)') || line.include?('copyright (c)'))
                        found = true
                      end
                      tempLines << line
                      break if line.include?('-->')
                    end
                    if endedPrematurely && found
                      Jekyll.logger.error("BROKEN SAMPLE REFERENCE - INCORRECT LINE SELECTION FORMAT sampleRef:#{target} in #{parent.document.attributes["docfile"]} - endLine reached at copyright notice that is set to be ignored (this is a default setting)")
                      create_pass_block parent, " ", attrs, subs: nil
                      return
                    elsif endedPrematurely
                      Jekyll.logger.warn("ENDLINE REACHED IN COMMENTED SECTION - sampleRef:#{target} in #{parent.document.attributes["docfile"]} - endLine reached before end of comment, could not determine if it contains copyright")
                      create_pass_block parent, " ", attrs, subs: nil
                      return
                    elsif !found
                      #Jekyll.logger.warn("COPYRIGHT NOTICE NOT FOUND WHEN THE FIRST LINE WAS A COMMENT- sampleRef:#{target} in #{parent.document.attributes["docfile"]} - could not find copyright")
                      content.each_line do |line|
                        current_line += 1
                        next if line.include?('<!-- used in docs --->')
                        break if endLine != -1 && current_line > endLine
                        lines << line
                      end
                    else
                      #Jekyll.logger.warn("COPYRIGHT NOTICE FOUND - sampleRef:#{target} in #{parent.document.attributes["docfile"]} - including content after notice")
                      allLines = content.split("\n")
                      strippedLines = allLines[current_temp_line..-1]
                      strippedLines.each do |line|
                        current_line += 1
                        next if line.include?('<!-- used in docs --->')
                        break if endLine != -1 && current_line > endLine
                        lines << line + "\n"
                      end
                    end
                  else
                    #Jekyll.logger.warn("COPYRIGHT NOTICE NOT FOUND - sampleRef:#{target} in #{parent.document.attributes["docfile"]} - could not find copyright")
                    content.each_line do |line|
                      current_line += 1
                      #next if current_line < startLine
                      next if line.include?('<!-- used in docs --->')
                      break if endLine != -1 && current_line > endLine
                      lines << line
                    end
                  end
                elsif (startPattern != nil && endPattern != nil)
                  foundStart = false
                  foundEnd = false
                  #Jekyll.logger.warn("PATTERN SELECTION - sampleRef:#{target} in #{parent.document.attributes["docfile"]} - startPattern: #{startPattern}, endPattern: #{endPattern}")
                  IO.foreach(filePath) do |line|
                    current_line += 1
                    next if current_line < startLine
                    next if line.include?('<!-- used in docs --->')
                    break if endLine != -1 && current_line > endLine
                    if foundStart && line.match?(endPattern)
                      lines << line
                      foundEnd = true
                      break
                    elsif foundStart
                      lines << line
                    elsif !foundStart && line.match?(startPattern)
                      foundStart = true
                      lines << line
                    end
                  end
                  if !foundStart
                    Jekyll.logger.error("BROKEN SAMPLE REFERENCE - INCORRECT PATTERN SELECTION FORMAT sampleRef:#{target} in #{parent.document.attributes["docfile"]} - startPattern not found")
                    create_pass_block parent, " ", attrs, subs: nil
                    return
                  elsif !foundEnd
                    Jekyll.logger.error("BROKEN SAMPLE REFERENCE - INCORRECT PATTERN SELECTION FORMAT sampleRef:#{target} in #{parent.document.attributes["docfile"]} - endPattern not found")
                    create_pass_block parent, " ", attrs, subs: nil
                    return
                  end
                elsif (includeOnlyTag != nil)
                  foundStart = false
                  foundStartCorrectOrder = false
                  foundEnd = false
                  currentTagLevel = 0
                  currentOrder = 0
                  #Jekyll.logger.warn("TAG SELECTION - sampleRef:#{target} in #{parent.document.attributes["docfile"]} - includeOnlyTag: #{includeOnlyTag}, includeOnlyTagLevel: #{includeOnlyTagLevel}, includeOnlyTagOrder: #{includeOnlyTagOrder}")
                  IO.foreach(filePath) do |line|
                    current_line += 1
                    next if current_line < startLine
                    next if line.include?('<!-- used in docs --->')
                    break if endLine != -1 && current_line > endLine
                    if (line.include?("<#{includeOnlyTag}") && currentTagLevel == includeOnlyTagLevel)
                      foundStart = true
                      currentTagLevel += 1
                      if currentOrder == includeOnlyTagOrder
                        foundStartCorrectOrder = true
                        lines << line
                      end
                    elsif (line.include?("<#{includeOnlyTag}") && foundStartCorrectOrder)
                      currentTagLevel += 1
                      lines << line
                    elsif (line.include?("<#{includeOnlyTag}"))
                      currentTagLevel += 1
                    elsif (line.include?("</#{includeOnlyTag}") && currentTagLevel == includeOnlyTagLevel+1)
                      currentTagLevel -= 1
                      if foundStartCorrectOrder == true
                        foundEnd = true
                        lines << line
                        break
                      else
                        foundStart = false
                        currentOrder += 1
                      end
                    elsif (line.include?("</#{includeOnlyTag}") && foundStartCorrectOrder)
                      currentTagLevel -= 1
                      lines << line
                    elsif (line.include?("</#{includeOnlyTag}") && foundStart)
                      currentTagLevel -= 1
                    elsif foundStartCorrectOrder
                      lines << line
                    end
                  end
                  if !foundStartCorrectOrder
                    Jekyll.logger.error("BROKEN SAMPLE REFERENCE - INCORRECT TAG SELECTION FORMAT sampleRef:#{target} in #{parent.document.attributes["docfile"]} - start tag not found")
                    create_pass_block parent, " ", attrs, subs: nil
                    return
                  elsif !foundEnd
                    Jekyll.logger.error("BROKEN SAMPLE REFERENCE - INCORRECT TAG SELECTION FORMAT sampleRef:#{target} in #{parent.document.attributes["docfile"]} - end tag not found")
                    create_pass_block parent, " ", attrs, subs: nil
                    return
                  end
                else
                  IO.foreach(filePath) do |line|
                    current_line += 1
                    next if current_line < startLine
                    next if line.include?('<!-- used in docs --->')
                    break if endLine != -1 && current_line > endLine
                    lines << line
                  end
                end

                if fileExt == "csv"
                    if (startLine > 1 && (attrs['includeHeader'] == nil || attrs['includeHeader'] == true))
                        header = IO.foreach(filePath).first
                        csv_content = <<~CSV
                        [format="csv",options="header"]
                        |===
                        #{header}
                        #{lines.join("\n")}
                        |===
                        CSV
                    elsif startLine > 1
                        csv_content = <<~CSV
                        [format="csv"]
                        |===

                        #{lines.join("\n")}
                        |===
                        CSV
                    else
                        csv_content = <<~CSV
                        [format="csv",options="header"]
                        |===
                        #{lines.join("\n")}
                        |===
                        CSV
                    end
                    samplesHtml = Asciidoctor.convert(csv_content, safe: :safe, extensions: false)
                else
                    source_content = <<~SOURCE
                      [source,#{fileExt}]
                      ----
                      #{lines.join("")}
                      ----
                    SOURCE
                    samplesHtml = Asciidoctor.convert(source_content, safe: :safe, extensions: false, attributes: { 'source-highlighter' => 'rouge' })
                end

                create_pass_block parent, samplesHtml, attrs, subs: nil
            elsif (branch != nil)
                Jekyll.logger.error("BROKEN MIDPOINT REFERENCE midpointRef:#{target}, branch:#{branch} in #{parent.document.attributes["docfile"]}")
                create_pass_block parent, " ", attrs, subs: nil
                return
            else
                Jekyll.logger.error("BROKEN SAMPLE REFERENCE sampleRef:#{target} in #{parent.document.attributes["docfile"]}")
                create_pass_block parent, " ", attrs, subs: nil
                return
            end
        end

    end

    class XrefInlineMacro < JekyllInlineMacro
        use_dsl

      named :xref
      name_positional_attributes 'linktext'

      # Check if there is an sprecific midpoint version included in link
      def process(parent, target, attrs)
        #verArr = readVersions(docsDir()) #???????????????????????

        if jekyllSite().config['environment']['name'].include?("docs")

            document_path = parent.document.attributes['docfile']

            negativeLookAhead = VersionReader.get_config_value('negativeLookAhead')

            if (!document_path.include?("/midpoint/reference/") || document_path.include?("midpoint/reference/index.html"))
                if (!target.include?("/midpoint/reference/"))
                    processXRefLink(parent, target, attrs)
                elsif (target.match?(negativeLookAhead))
                    if document_path.match?(/\/midpoint\/release\/.+/)
                        parentVer = document_path.split("/")[4]
                        if (VersionReader.get_config_value('releaseDocsVerMap').key?(parentVer))
                            replaceVersion = VersionReader.get_config_value('releaseDocsVerMap')[parentVer].to_s
                            editedTarget = target.gsub("/midpoint/reference/", "/midpoint/reference/#{replaceVersion}/")
                            processXRefLink(parent, editedTarget, attrs)
                        else
                            processXRefLink(parent, target.gsub("/midpoint/reference/", "/midpoint/reference/#{VersionReader.get_config_value('defaultBranch')}/"), attrs)
                        end
                    else
                        processXRefLink(parent, target.gsub("/midpoint/reference/", "/midpoint/reference/#{VersionReader.get_config_value('defaultBranch')}/"), attrs)
                    end
                else
                    Jekyll.logger.warn("Specific midpoint version included in link xref:#{target} in #{document_path}")
                    processXRefLink(parent, target, attrs)
                end
            else
                if (!target.include?("/midpoint/reference/"))
                    processXRefLink(parent, target, attrs)
                elsif (target.match?(negativeLookAhead))
                    currentPage = findCurrentPage(parent.document)
                    version = currentPage.data['midpointBranchSlug']
                    processXRefLink(parent, target.gsub("/midpoint/reference/", "/midpoint/reference/#{version}/"), attrs)
                else
                    Jekyll.logger.warn("Specific midpoint version included in link xref:#{target} in #{document_path}")
                    processXRefLink(parent, target, attrs)
                end
                #currentPage = findCurrentPage(parent.document)S
            end
        else
            processXRefLink(parent, target, attrs)
        end
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

        targetUrl = nil
        mid = /\AMID\-(\d+)\z/.match(target)
        if mid
            targetUrl = "https://support.evolveum.com/projects/midpoint/work_packages/#{mid[1]}"
        elsif /\A\d+\z/.match(target)
            targetUrl = "https://support.evolveum.com/projects/midpoint/work_packages/#{target}"
        else
            sourceFile = parent.document.attributes["docfile"]
            Jekyll.logger.error("Wrong bug reference bug:#{target} in #{sourceFile}")
        end

        if targetUrl
#            puts "BBBUG: #{target} -> #{targetUrl}"
            createLink(targetUrl, parent, attrs, target)
        end
      end
    end

    class SamplesBlockMacro < JekyllBlockMacro
        use_dsl

        named :sampleRef
        name_positional_attributes 'lines'

        def process(parent, target, attrs)
            processCodeInclude(parent, target, attrs, "#{samplesDir()}/#{target}", nil)
        end

    end

    # This plugin is for include code snippets from midpoint repository
    class MidpointBlockMacro < JekyllBlockMacro
        use_dsl

        named :midpointRef
        name_positional_attributes 'branch','lines'

        def process(parent, target, attrs)
            branch = "support-4.8"
            if attrs['branch'] != nil
                branch = attrs['branch']
            end
            processCodeInclude(parent, target, attrs, "#{midpointVersionsDir(branch)}/#{target}", branch)
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
        if glossary == nil
            Jekyll.logger.error("GLOSSARY DATA NOT FOUND, maybe the glossary.yml file is missing? This error can occur of you are using glossref macro in guide. If you want to have glossary in guide please contact Jan directly or open a ticket")
            return nil
        else
          glossentry = glossary.detect {|e| e['id'] == entry_id }
#        puts "GLOSSREF:entry: #{glossentry}"
        end
        return glossentry
      end

    end

    class FeatureInlineMacro < JekyllInlineMacro
      use_dsl

      named :feature
      name_positional_attributes 'linktext'

      def process(parent, target, attrs)

        feature = findFeature(target)
        if feature == nil
            sourceFile = parent.document.attributes["docfile"]
            Jekyll.logger.error("BROKEN FEATURE inline REFERENCE #{target} in #{sourceFile}")
            defaultLabel = target
            targetUrl = "#"  # fallback URL for broken references
        else
            defaultLabel = feature['title']
            targetUrl = feature['url']
        end
#        puts "FEATURE: #{target} -> #{targetUrl}"

        createLink(targetUrl, parent, attrs, defaultLabel, "feature")
      end

      def findFeature(entry_id)
        features = jekyllData('midpoint-features')
        feature = features.detect {|e| e['id'] == entry_id }
#        puts "FEATURE:entry: #{feature['title']}"
        return feature
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
            imageArr = document.find_by(context: :image)
            arrLenght = (imageArr.length) - 1
            imageArr.each_with_index do |image,index|
                target = image.attr('target')
                if index == arrLenght
                    image.set_attr("target",fixImagePath(target, document, currentPage, true))
                else
                    image.set_attr("target",fixImagePath(target, document, currentPage, false))
                end
            end
        end

        def fixImagePath(target, document, currentPage, last)
            #puts("IMAGEFIX: #{target}, #{currentPage.url}")
            targetPathname = Pathname.new(target)
            #Jekyll.logger.warn("IMAGEFIX: #{target} (#{targetPathname})")
            #Jekyll.logger.warn("IMAGESDIR: #{document.attr('imagesdir')}")
            if document.attr('imagesdir') != nil
              targetPathname = Pathname.new(document.attr('imagesdir') + target)
              if last
                  document.set_attr("imagesdir", nil)
              end
            end
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

            #Jekyll.logger.warn("IMAGEFIX: #{target} --> #{diffedTargetPathname.to_s} (#{diffedTargetFilePathname})")

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
  inline_macro Evolveum::FeatureInlineMacro
  block_macro Evolveum::SamplesBlockMacro
  block_macro Evolveum::MidpointBlockMacro
  treeprocessor Evolveum::ImagePathTreeprocessor
end
