

module Evolveum

    class BookInitializator

        def initialize(site)
            @site = site
            @bookTag = nil

            bookPath = site.config['docs']['bookPath']
            bookPath = File.expand_path(bookPath, site.source) unless File.absolute_path?(bookPath) == bookPath

            docsPath = site.config['docs']['docsPath']
            docsPath = File.expand_path(docsPath, site.source) unless File.absolute_path?(docsPath) == docsPath

            if site.config['environment'].include?("bookTag")
                @bookTag = site.config['environment']['bookTag']
            end

            #Jekyll.logger.warn("INFO: Book path is set to #{bookPath}, docs path is set to #{docsPath}")

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
                    if line =~ /^include::(.*)\[(.*)\]/
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
                    original_content = File.read(file, encoding: 'UTF-8')
                    current_lines = original_content.lines # Array of lines, each with \n

                    # 1. Remove include::chapter-include.adoc[]
                    initial_line_count = current_lines.length
                    current_lines.reject! { |line| line.strip == 'include::chapter-include.adoc[]' }
                    include_removed = current_lines.length != initial_line_count

                    # 2. Find title line index (line starting with a single '= ')
                    # We need to operate on stripped lines for matching, but keep original lines for reconstruction
                    title_line_index = current_lines.index { |l| stripped_line = l.strip; stripped_line.start_with?('= ') && !stripped_line.start_with?('==') }

                    unless title_line_index
                        Jekyll.logger.warn("WARN: No main title found in #{file}. Skipping attribute injection for this file.")
                        if include_removed # If only include was removed, write the file
                            File.write(file, current_lines.join)
                        end
                        next
                    end

                    # 3. Determine which attributes are missing (check against original_content to avoid re-adding if already present)
                    attributes_to_add = []
                    # Use multiline match 'm' for checking attributes that could be anywhere
                    unless original_content =~ /^:page-visibility:/m
                        attributes_to_add << ":page-visibility: visible"
                    end
                    unless original_content =~ /^:page-display-order:/m
                        attributes_to_add << ":page-display-order: #{chapters.index(relative_path) + 1}"
                    end
                    unless original_content =~ /^:imagesdir:/m
                        attributes_to_add << ":imagesdir: images/"
                    end

                    # 4. If no attributes to add and include was not removed, nothing changed.
                    if attributes_to_add.empty? && !include_removed
                        next
                    end

                    # 5. If attributes need to be added
                    if !attributes_to_add.empty?
                        new_attributes_block_content = attributes_to_add.join("\n") + "\n" # Ensure a newline after the block itself

                        # Determine the actual line index for insertion in the `current_lines` array
                        # This will be the line immediately after the title line.
                        insertion_array_index = title_line_index + 1

                        prefix_newline_string = ""
                        # Check if a blank line needs to be inserted *before* the attribute block.
                        # This is if the line immediately after the title exists, is not empty, and is not an attribute definition.
                        if current_lines.length > insertion_array_index # Check if a line exists after the title
                            line_after_title_stripped = current_lines[insertion_array_index].strip
                            if !line_after_title_stripped.empty? && !line_after_title_stripped.start_with?(':')
                                prefix_newline_string = "\n" # Add a blank line before attributes
                            end
                        end

                        final_attributes_string_to_insert = prefix_newline_string + new_attributes_block_content

                        # Insert the string containing all new attributes (and potentially a leading prefix newline)
                        # as a single element into the array of lines.
                        current_lines.insert(insertion_array_index, final_attributes_string_to_insert)
                    end

                    # 6. Write modified content back to the file (if any changes were made)
                    File.write(file, current_lines.join)
                # else (code for files not in chapters, if any, was here)
                #     content = File.read(file, encoding: 'UTF-8')
                #     content = content.gsub(/^\s*include::chapter-include\.adoc\[\]\s*$?/, '')
                #     if !(content =~ /^:page-visibility:/)
                #         content = ":page-visibility: hidden\n\n" + content
                #     end
                #     if !(content =~ /^:imagesdir:/)
                #       content = ":imagesdir: \"images/\"\n" + content
                #     end
                #     File.write(file, content)
                end
            end
            return chapters
        end


        def createBookDir()
            if (!File.exist?(@bookDir))
                system("mkdir -p #{@bookDir}")
            end
        end

        def config_recently_modified?(minutes = 7)
          config_path = File.join(@docsDir, '_config.yml')
          return false unless File.exist?(config_path)

          file_mod_time = File.mtime(config_path)
          #Jekyll.logger.warn "INFO: _config.yml last modified at #{file_mod_time}"
          (Time.now - file_mod_time) < (minutes * 60)
        end

        def cloneBook()
          config_changed = config_recently_modified?

          if (!File.exist?(@bookDir + "/.git"))
            @bookTag ? system("cd #{@bookDir} && git clone -b #{@bookTag} #{@bookGH} .") : system("cd #{@bookDir} && git clone #{@bookGH} .")
          elsif config_changed
            # If config has changed, update the book
            Jekyll.logger.info "INFO: _config.yml recently modified, updating book repository"
            system("rm -rf  #{@bookDir} && mkdir -p #{@bookDir}")
            @bookTag ? system("cd #{@bookDir} && git clone -b #{@bookTag} #{@bookGH} .") : system("cd #{@bookDir} && git clone #{@bookGH} .")
          end
        end

        def updateSymlinks(chapters)
          target_dir = "#{@docsDir}/book/"

          book_files = chapters.map { |chapter| File.join(@bookDir, chapter) }

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
            chapters = setVisibilitiesAndOrders()
            updateSymlinks(chapters)
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
