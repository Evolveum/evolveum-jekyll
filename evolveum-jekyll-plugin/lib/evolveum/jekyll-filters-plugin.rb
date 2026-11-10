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

        PAGE_TOC_HEADING = /<h([23])\b[^>]*\bid="([^"]+)"[^>]*>(.*?)<\/h\1>/m

        def page_toc(html, min = 2)
            headings = html.to_s.scan(PAGE_TOC_HEADING).map do |level, id, inner|
                text = inner.gsub(/<a class="anchor"[^>]*><\/a>/, '').gsub(/<[^>]+>/, '').gsub(/\s+/, ' ').strip
                [level, id, text]
            end
            return '' if headings.length < min.to_i
            s = StringIO.new
            s << '<nav class="ev-page-toc" aria-labelledby="ev-page-toc-title">'
            s << '<h2 id="ev-page-toc-title" class="ev-aside__title">On this page</h2>'
            s << '<ul>'
            open_item = false
            open_sub = false
            headings.each do |level, id, text|
                link = "<a href=\"##{id}\">#{text}</a>"
                if level == '3' && open_item
                    s << '<ul>' unless open_sub
                    open_sub = true
                    s << "<li>#{link}</li>"
                else
                    s << '</ul>' if open_sub
                    s << '</li>' if open_item
                    open_sub = false
                    s << "<li>#{link}"
                    open_item = level == '2'
                    s << '</li>' unless open_item
                end
            end
            s << '</ul>' if open_sub
            s << '</li>' if open_item
            s << '</ul></nav>'
            s.string
        end
    end

end

Liquid::Template.register_filter(Evolveum::Filters)
