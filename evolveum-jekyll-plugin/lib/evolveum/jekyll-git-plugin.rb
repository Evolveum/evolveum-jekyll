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

module Evolveum

    class Git

        def self.post_read(site)
            site.pages.each do |page|
                update(page)
            end
        end

        def self.update(page)
            lastModDate = nil
            if page.path != nil && File.exists?(page.path)
                dateString = git("log -1 --pretty='format:%ci' '#{page.path}'")
                if dateString != nil
                    lastModDate = DateTime.parse(dateString)
                    page.data['lastModificationDate'] = lastModDate
                end
            end
            puts("  [U] #{page.path}: #{lastModDate}")
        end

        def self.git(argString)
            out = `git #{argString}`
            if !$?.success?
                puts("ERROR executing git: $?")
                return nil
            end
            return out
        end

    end

end

Jekyll::Hooks.register :site, :post_read do |site|
    puts "=========[ EVOLVEUM GIT ]============== post_read #{site}"
    Evolveum::Git.post_read(site)
end
