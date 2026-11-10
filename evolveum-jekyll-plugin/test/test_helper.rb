require "minitest/autorun"
require "tmpdir"
require "jekyll"
require "evolveum/jekyll-nav-plugin"

FakePage = Struct.new(:url, :data)
FakeSite = Struct.new(:pages, :data, :config)

SECTION_CONFIG = { "navigation" => { "sidebar" => "section" } }.freeze

module NavTestHelpers
  def build_site(pages_spec, navbar: [], config: {})
    pages = pages_spec.map { |url, data| FakePage.new(url, data.dup) }
    FakeSite.new(pages, { "navbar" => navbar }, config)
  end

  def build_tree(pages_spec, navbar: [], config: {})
    Evolveum::Nav.construct(build_site(pages_spec, navbar: navbar, config: config))
  end

  def render_tag(tag_name, tree, url, config = {})
    site = { "data" => { "nav" => tree } }.merge(config)
    Liquid::Template.parse("{% #{tag_name} %}").render!("site" => site, "page" => { "url" => url })
  end

  def capture_warnings
    warnings = []
    logger = Jekyll.logger
    logger.define_singleton_method(:warn) { |*args| warnings << args.compact.join(" ") }
    yield
    warnings
  ensure
    logger.singleton_class.send(:remove_method, :warn)
  end

  def page_for(tree, url)
    tree.find(url).page
  end
end

class Minitest::Test
  include NavTestHelpers
end
