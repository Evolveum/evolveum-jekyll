module Evolveum

    module AccessibleAdmonitions

        TABLE = /(<div[^>]*class="admonitionblock[^"]*"[^>]*>\s*)<table>/
        ICON = /(<td class="icon">\s*)<i class="([^"]*)" title="([^"]*)"><\/i>/

        def self.label(title)
            text = title.strip.sub(/\Asince version\z/i, 'Since')
            text[0].upcase + text[1..]
        end

        def self.process(html)
            html
                .gsub(TABLE, '\1<table role="presentation">')
                .gsub(ICON) { "#{$1}<i class=\"#{$2}\" title=\"#{$3}\" aria-hidden=\"true\"></i><span class=\"ev-visually-hidden\">#{label($3)}: </span>" }
        end

    end

end

Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
    if doc.output && doc.output.include?('admonitionblock')
        doc.output = Evolveum::AccessibleAdmonitions.process(doc.output)
    end
end
