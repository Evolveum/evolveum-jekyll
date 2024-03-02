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
            if page.path != nil && File.exists?(page.path)
                #puts(page.path)
                # todo add somewhere index.html
                if page.path != "midpoint/reference/index.html" && page.path.include?("midpoint/reference/")
                    urlSplitted = page.path.split("/")
                    branch = urlSplitted[2]
                    dateString = git("log -1 --pretty='format:%ci' 'docs/#{urlSplitted.drop(3).join("/")}'", branch, mpDir)
                elsif
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
