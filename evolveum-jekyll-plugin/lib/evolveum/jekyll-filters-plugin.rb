# (C) 2021 Evolveum
#
# Evolveum filter Plugin for Jekyll
#
# TODO
#

module Evolveum

    module Filters
        def escape_paragraph(input, separator)
            separator.gsub!(/\\n/, "\n")
            input.gsub(/\n/, separator)
            #"FFFFFFF:#{input}:#{separator}:"
        end
    end

end

Liquid::Template.register_filter(Evolveum::Filters)
