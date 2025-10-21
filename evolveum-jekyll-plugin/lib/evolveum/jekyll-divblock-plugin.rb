# This is a Jekyll plugin that defines a custom Liquid block tag 'divblock'.
# The 'divblock' tag wraps its content inside a <div> element with a specified CSS class.
# It is usefull for adding divs with custom classes without any other components inside.
# It is used for example for mermaid diagrams to work properly.
# It could be easily replaced by passthrough HTML, but as a design philosophy we try to avoid
# mixing HTML with adoc content as much as possible.

module Evolveum

  class DivBlock < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super
      @class_name = markup.strip
    end

    def render(context)
      content = super
      "<div class=\"#{@class_name}\">#{content}</div>"
    end
  end

  class Mermaid < DivBlock
    def initialize(tag_name, markup, tokens)
      super
      @class_name = "mermaid"
    end
  end

end

Liquid::Template.register_tag('divblock', Evolveum::DivBlock)
Liquid::Template.register_tag('mermaid', Evolveum::Mermaid)
