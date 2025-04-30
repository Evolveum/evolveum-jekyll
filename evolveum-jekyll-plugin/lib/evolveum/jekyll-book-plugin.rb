

module Evolveum

    class BookInitializator

        def initialize(site)
            @site = site
            @bookDir = site.config['docs']['bookPath'] + site.config['docs']['bookDirName']
            @bookGH = site.config['docs']['bookGH']
            @docsDir = site.config['docs']['docsPath'] + site.config['docs']['docsDirName']
        end

        def createBookDir()
            if (!File.exist?(@bookDir))
                system("mkdir -p #{@bookDir}")
            end
        end

        def cloneBook()
            if (!File.exist?(@bookDir + "/.git"))
                system("cd #{@bookDir} && git clone #{@bookGH} .")
            else
                system("cd #{@bookDir} && git pull")
            end
        end

        def updateSymlinks()
          target_dir = "#{@docsDir}/book/"

          book_files = Dir.glob("#{@bookDir}/*.adoc").select { |f| File.file?(f) }

          existing_symlinks = Dir.glob("#{target_dir}/*").select { |f| File.symlink?(f) }
          existing_symlink_paths = existing_symlinks.map { |s| File.expand_path(File.readlink(s), File.dirname(s)) }

          book_files.each do |file|
            relative_path = file.sub(@bookDir + '/', '')
            symlink_path = "#{target_dir}#{relative_path}"
            symlink_dir = File.dirname(symlink_path)
          end

          # Remove invalid symlinks
          existing_symlinks.each do |symlink|
            target = File.expand_path(File.readlink(symlink), File.dirname(symlink))
            FileUtils.rm(symlink) if !File.exist?(target) || !book_files.include?(target)
          end

          # Directory part - sync images and samples
          ["images", "samples"].each do |special_dir|
              source_dir = "#{@bookDir}/#{special_dir}"
              target_symlink = "#{target_dir}#{special_dir}"

              if File.directory?(source_dir) && !File.exist?(target_symlink) && !File.symlink?(target_symlink)
                FileUtils.ln_sf(source_dir, target_symlink)
              elsif !File.symlink?(target_symlink) && File.exist?(target_symlink)
                Jekyll.logger.error "ERROR: #{target_symlink} exists and is not a symlink. Skipping."
              end
            end
        end

        def addBook()
            createBookDir()
            cloneBook()
            updateSymlinks()
        end
    end
end

Jekyll::Hooks.register :site, :after_init do |site|
  puts "=========[ EVOLVEUM BOOK INITIALIZATION ]============== after_init"
  if site.config['environment']['name'].include?("docs")
    book_initializator = Evolveum::BookInitializator.new(site)
    book_initializator.addBook()
  end
end
