# (C) 2021 Evolveum
#
# Common code for Evolveum plugins
#

module Evolveum

    class Generator < Jekyll::Generator

        def generate(site)
            # doing nothing, this is an "abstract" class
        end

        protected

        def sourceFilePath(filename)
          File.expand_path filename, __dir__
        end

        # Checks if a file already exists in the site source
        def pageExists?(file_path)
          @site.pages.any? { |p| p.url == "/#{file_path}" }
        end

    end

end
