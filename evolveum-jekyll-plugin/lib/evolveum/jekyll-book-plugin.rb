

module Evolveum

    class BookInitializator

        def initialize(site)
            @site = site

            bookPath = site.config['docs']['bookPath']
            bookPath = File.expand_path(bookPath, site.source) unless File.absolute_path?(bookPath) == bookPath

            docsPath = site.config['docs']['docsPath']
            docsPath = File.expand_path(docsPath, site.source) unless File.absolute_path?(docsPath) == docsPath

            Jekyll.logger.warn("INFO: Book path is set to #{bookPath}, docs path is set to #{docsPath}")

            # Use File.join for proper path construction
            @bookDir = File.join(bookPath, site.config['docs']['bookDirName'])
            @bookGH = site.config['docs']['bookGH']
            @docsDir = File.join(docsPath, site.config['docs']['docsDirName'])
        end

        # def update_chapter_include_file
        #   chapter_include_path = File.join(@bookDir, "chapter-include.adoc")

        #   if File.exist?(chapter_include_path)
        #     content = File.read(chapter_include_path)
        #     unless content.include?(":imagesdir: images")
        #       # Append the line to the file
        #       File.open(chapter_include_path, 'a') do |file|
        #         file.puts("\n:imagesdir: images")
        #       end
        #       Jekyll.logger.info("INFO: Added  to chapter-include.adoc")
        #     end
        #   else
        #     # Create the file if it doesn't exist
        #     File.open(chapter_include_path, 'w') do |file|
        #       file.puts(":imagesdir: images")
        #     end
        #     Jekyll.logger.info("INFO: Created chapter-include.adoc with :imagesdir: images")
        #   end
        # end

        # We need this because otherwise ther would be todo pages in nav. Also the capters will be order alphabetically instead of by number
        def setVisibilitiesAndOrders()
            chapters = []
            File.open(@bookDir + "/master.adoc", 'r:UTF-8') do |file|
                file.each_line do |line|
                    if line =~ /include::(.*)\[(.*)\]/
                          chapter_name = line.sub(/include::/, '').sub(/\[(.*)\]/, '').strip
                          # In colophon there are some variables that we currently cannot add
                          if chapter_name != "colophon.adoc"
                              chapters.push(chapter_name)
                          end
                    end
                end
            end
            book_files = Dir.glob("#{@bookDir}/*.adoc").select { |f| File.file?(f) }
            book_files.each do |file|
                relative_path = file.sub(@bookDir + '/', '')
                if chapters.include?(relative_path)
                    # Set visibility and order for the chapter
                      content = File.read(file, encoding: 'UTF-8')
                      # Check if the file already contains a page-visibility attribute
                      if !(content =~ /^:page-visibility:/)
                        # Add the page-visibility attribute at the beginning of the file
                        if !(content.strip[0] != ":")
                          content = "\n" + content
                        end
                        content = ":page-visibility: visible\n" + content
                      end
                      # Check if the file already contains a page-order attribute
                      if !(content =~ /^:page-order:/)
                        # Add the page-order attribute at the beginning of the file
                        content = ":page-display-order: #{chapters.index(relative_path) + 1}\n" + content
                      end

                      if !(content =~ /^:imagesdir:/)
                        # Add the imagesdir attribute at the beginning of the file
                        content = ":imagesdir: images\n" + content
                      end
                      # Write the modified content back to the file
                      File.write(file, content)
                else
                    content = File.read(file, encoding: 'UTF-8')
                    if !(content =~ /^:page-visibility:/)
                        # Add the page-visibility attribute at the beginning of the file
                        new_content = ":page-visibility: hidden\n\n" + content
                        File.write(file, new_content)
                    end
                end
            end
        end


        def createBookDir()
            if (!File.exist?(@bookDir))
                system("mkdir -p #{@bookDir}")
            end
        end

        def cloneBook()
            if (!File.exist?(@bookDir + "/.git"))
                system("cd #{@bookDir} && git clone #{@bookGH} .")
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
            if !File.exist?("#{@docsDir}/book/#{relative_path}")
              FileUtils.ln_sf(file, symlink_path)
            end
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
            setVisibilitiesAndOrders()
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
