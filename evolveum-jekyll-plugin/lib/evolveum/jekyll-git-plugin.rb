# (C) 2020 Evolveum
#
# Evolveum Git Plugin for Jekyll
#
# This plugin is used to implement git-related functionality,
# such as determining page last modification date, page history, etc.
#
# This plugin is designed to work with Evolveum Jekyll theme.
#

require 'date'
require 'open3'

module Evolveum

    class Git

        def self.post_read(site)
            mpDir = site.config['docs']['midpointVersionsPath'] + site.config['docs']['midpointVersionsPrefix']
            site.pages.each do |page|
                update(page, mpDir)
            end
        end

        def self.update(page, mpDir)
            lastModDate = nil
            if page.path != nil && File.exist?(page.path)
                #puts(page.path)
                # todo add somewhere index.html
                if page.path != "midpoint/reference/index.html" && page.path.include?("midpoint/reference/")
                    dateString = git("log -1 --pretty='format:%ci' '#{page.path.gsub("midpoint/reference/#{page.data['midpointBranchSlug']}/","docs/")}'", page.data['midpointBranchSlug'], mpDir)
                elsif page.path != "midpoint/release/index.html" && page.path.include?("midpoint/release/") && page.data['docsReleaseBranch'] != nil && Dir.exist?("#{mpDir}#{page.data['docsReleaseBranch']}")
                    if page.path.include?("install")
                        dateString = git("log -1 --pretty='format:%ci' 'install-dist.adoc'", page.data['docsReleaseBranch'], mpDir)
                    else
                        dateString = git("log -1 --pretty='format:%ci' 'release-notes.adoc'", page.data['docsReleaseBranch'], mpDir)
                    end
                else
                    dateString = git("log -1 --pretty='format:%ci' '#{page.path}'", nil, nil)
                end

                if dateString != nil && !dateString.empty?
                    begin
                        lastModDate = DateTime.parse(dateString)
                    rescue Date::Error => e
                        STDERR.puts("Error parsing last modification date \"#{dateString}\" for file #{page.path}: #{e}")
                        lastModDate = nil
                    end
                    page.data['lastModificationDate'] = lastModDate
                end
            end
            #puts("  [U] #{page.path}: #{lastModDate}")
        end

        def self.git(argString, branch, mpDir)
            if branch == nil
                out = `git #{argString}`
            else
                out, _ = Open3.capture2("cd #{mpDir}#{branch}/ && git #{argString}")
            end

            if !$?.success?
                puts("ERROR executing git: $?")
                return nil
            end
            return out
        end

    end

end

Jekyll::Hooks.register :site, :post_read do |site|
    #puts "=========[ EVOLVEUM GIT ]============== post_read"
    Evolveum::Git.post_read(site)
end
