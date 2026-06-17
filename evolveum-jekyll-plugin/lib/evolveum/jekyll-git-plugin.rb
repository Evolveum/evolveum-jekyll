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
require 'pathname'

module Evolveum

    class Git
        INCLUDE_REGEX = /include::([^\[]+)\[\]/
        IMAGE_REGEX = /image::([^\[]+)\[\]/
        DATA_REF_REGEX = /\{[\}\%].*site\.data\.([\w\-]+).*[\}\%]\}/
        REMOTE_IMAGE_REGEX = %r{^https?://}

        def self.post_read(site)
            mpDir = site.config['docs']['midpointVersionsPath'] + site.config['docs']['midpointVersionsPrefix']
            bookPath = site.config['docs']['bookPath']
            bookPath = File.expand_path(bookPath, site.source) unless File.absolute_path?(bookPath) == bookPath
            bookDir = File.join(bookPath, site.config['docs']['bookDirName'])
            site.pages.each do |page|
                deps = self.extract_assets(page)
                update(page, mpDir, bookDir, deps)
            end
        end

        def self.git_date_for_path(file_path, page_data, mpDir, bookDir, base_dir = nil)
            check_path = file_path
            if base_dir && !Pathname.new(file_path).absolute?
                check_path = File.join(base_dir, file_path)
            end
            
            return nil unless file_path && File.exist?(check_path)
            
            # 1. Midpoint Reference
            if file_path != "midpoint/reference/index.html" && file_path.include?("midpoint/reference/") && page_data && page_data['midpointBranchSlug']
                transformed = file_path.gsub("midpoint/reference/#{page_data['midpointBranchSlug']}/", "docs/")
                repo_dir = "#{mpDir}#{page_data['midpointBranchSlug']}/"
                ensure_git_cache_built(repo_dir, "docs")
                cache_key = "#{repo_dir}::docs"
                return @git_date_caches[cache_key][transformed] if @git_date_caches[cache_key].key?(transformed)
                
                date_str = git("log -1 --pretty='format:%ct' '#{transformed}'", page_data['midpointBranchSlug'], mpDir)
                return parse_git_date(date_str, file_path)
                
            # 2. Midpoint Release
            elsif file_path != "midpoint/release/index.html" && file_path.include?("midpoint/release/") && page_data && page_data['docsReleaseBranch'] && Dir.exist?("#{mpDir}#{page_data['docsReleaseBranch']}")
                if file_path.include?("install")
                    date_str = git("log -1 --pretty='format:%ct' 'install-dist.adoc'", page_data['docsReleaseBranch'], mpDir)
                else
                    date_str = git("log -1 --pretty='format:%ct' 'release-notes.adoc'", page_data['docsReleaseBranch'], mpDir)
                end
                return parse_git_date(date_str, file_path)
                
            # 3. Book Directory
            elsif file_path != "book/index.html" && file_path.include?("book/") && Dir.exist?(bookDir)
                transformed = file_path.gsub("book/", "")
                ensure_git_cache_built(bookDir)
                return @git_date_caches[bookDir][transformed] if @git_date_caches[bookDir].key?(transformed)
                
                date_str = git("log -1 --pretty='format:%ct' '#{transformed}'", nil, bookDir, true)
                return parse_git_date(date_str, file_path)
            end
            
            # 4. Standard Main Repository
            if base_dir
                ensure_git_cache_built(base_dir)
                
                cache_key = file_path
                if Pathname.new(file_path).absolute?
                    begin
                        cache_key = Pathname.new(file_path).relative_path_from(Pathname.new(base_dir)).to_s
                    rescue ArgumentError
                        cache_key = file_path
                    end
                end
                
                return @git_date_caches[base_dir][cache_key] if @git_date_caches[base_dir].key?(cache_key)
            end
            
            # 5. Fallback for untracked files or if cache building failed
            date_str = git("log -1 --pretty='format:%ct' '#{file_path}'", nil, nil)
            parse_git_date(date_str, file_path)
        end

        def self.ensure_git_cache_built(repo_dir, path = nil)
            @git_date_caches ||= {}
            cache_key = path ? "#{repo_dir}::#{path}" : repo_dir
            return if @git_date_caches.key?(cache_key)
            
            cache = {}
            cmd = "git log --name-only --pretty='format:%ct'"
            cmd += " -- #{path}" if path
            out, status = Open3.capture2(cmd, chdir: repo_dir)
            
            if status.success?
                current_time = nil
                out.each_line do |line|
                    line = line.strip
                    next if line.empty?
                    if line.match?(/^\d+$/)
                        current_time = Time.at(line.to_i)
                    else
                        cache[line] = current_time unless cache.key?(line)
                    end
                end
            end
            @git_date_caches[cache_key] = cache
        end

        def self.parse_git_date(date_str, file_path)
            return nil if date_str.nil? || date_str.empty?
            begin
                Time.at(date_str.strip.to_i)
            rescue ArgumentError => e
                STDERR.puts("Error parsing git timestamp \"#{date_str}\" for file #{file_path}: #{e}")
                nil
            end
        end

        def self.update(page, mpDir, bookDir, dependency_files = [])
            base_dir = page.respond_to?(:site) && page.site && page.site.source ? page.site.source : nil
            base_pathname = base_dir ? Pathname.new(base_dir) : nil
            
            page_git_date = self.git_date_for_path(page.path, page.data, mpDir, bookDir, base_dir)
            #puts("[GIT] Page #{page.path}: #{page_git_date.inspect}")

            dep_dates = []
            
            dependency_files.each do |dep|
                next unless File.exist?(dep)
                
                # Convert absolute path to repository-relative path
                git_path = dep
                if base_pathname
                    begin
                        git_path = Pathname.new(dep).relative_path_from(base_pathname).to_s
                    rescue ArgumentError
                        # dep is outside base_dir, try to use as-is
                        git_path = dep
                    end
                end
                
                dep_date = self.git_date_for_path(git_path, page.data, mpDir, bookDir, base_dir)
                #puts("[GIT]   Dependency #{git_path}: #{dep_date.inspect}")
                dep_dates << dep_date if dep_date
            end
            
            # Compute effective date: newest of page and all dependencies
            all_dates = []
            all_dates << page_git_date if page_git_date
            all_dates.concat(dep_dates)
            
            if all_dates.empty?
                #puts("[GIT] No git dates found for #{page.path}")
            else
                effective_date = all_dates.max
                #puts("[GIT] Effective date for #{page.path}: #{effective_date}")
                page.data['lastModificationDate'] = effective_date
            end
        end

        def self.git(argString, branch, dir = nil, book = nil)
            if branch == nil && !book
                out, _ = Open3.capture2("git #{argString}")
            elsif book
                out, _ = Open3.capture2("cd #{dir} && git #{argString}")
            else
                out, _ = Open3.capture2("cd #{dir}#{branch}/ && git #{argString}")
            end

            if !$?.success?
                puts("ERROR executing git: #{$?.inspect}")
                return nil
            end
            return out
        end

        def self.extract_assets(page)
            content = page.respond_to?(:content) && page.content ? page.content : ""
            
            includes = content.scan(INCLUDE_REGEX).flatten
            asciidoc_images = content.scan(IMAGE_REGEX).flatten
            data_refs = content.scan(DATA_REF_REGEX).flatten

            abs_paths = []
            if page.respond_to?(:site) && page.site && page.site.source
                base_dir = page.site.source
                page_dir = File.dirname(page.path || "")
                
                # Helper to resolve relative paths
                resolve_path = lambda { |path, dir|
                    return path if Pathname.new(path).absolute?
                    rel_path = File.join(dir, path)
                    resolved = File.expand_path(rel_path, base_dir)
                    resolved = File.expand_path(path, base_dir) unless File.exist?(resolved)
                    resolved
                }
                
                includes.each { |inc| abs_paths << resolve_path.call(inc, page_dir) }
                
                asciidoc_images.each do |img|
                    next if img =~ REMOTE_IMAGE_REGEX  # Skip remote images
                    abs_paths << resolve_path.call(img, page_dir)
                end
                
                data_refs.each do |ref|
                    abs_paths << File.join(base_dir, "_data", "#{ref}.yml")
                end
            end
            abs_paths.uniq
        end

    end

end

Jekyll::Hooks.register :site, :post_read do |site|
    #puts "=========[ EVOLVEUM GIT ]============== post_read"
    Evolveum::Git.post_read(site)
end
