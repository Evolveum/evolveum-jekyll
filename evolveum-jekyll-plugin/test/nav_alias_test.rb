require_relative "test_helper"

class NavAliasTest < Minitest::Test
  ALIAS_PAGES = {
    "/about/" => { "title" => "About" },
    "/about/writing/" => { "title" => "Writing", "alias" => { "parent" => "/midpoint/" } },
    "/midpoint/" => { "title" => "MidPoint" },
    "/midpoint/tools/" => { "title" => "Tools" },
    "/midpoint/tools/cli/" => { "title" => "CLI", "alias" => { "parent" => "/midpoint/" } },
    "/midpoint/survey/" => { "title" => "Survey", "alias" => { "parent" => "/community/surveys/", "slug" => "midscale" } }
  }.freeze

  def setup
    @warnings = capture_warnings { @tree = build_tree(ALIAS_PAGES) }
  end

  def test_missing_parent_creates_no_nodes
    assert_nil @tree.find("/community/")
  end

  def test_missing_parent_warns
    assert @warnings.any? { |w| w.include?("/community/surveys/") && w.include?("/midpoint/survey/") }, @warnings.inspect
  end

  def test_cross_section_alias_renders
    assert_includes @tree.find("/midpoint/").subnodes.map(&:url), "/about/writing/"
  end

  def test_cross_section_alias_warns
    assert @warnings.any? { |w| w.include?("/about/writing/") && w.include?("/midpoint/") && w.include?("section") }, @warnings.inspect
  end

  def test_same_section_alias_silent
    refute @warnings.any? { |w| w.include?("/midpoint/tools/cli/") }, @warnings.inspect
  end

  def test_second_pass_adds_no_warnings_or_nodes
    site = build_site(ALIAS_PAGES)
    tree = nil
    warnings = capture_warnings do
      tree = Evolveum::Nav.construct(site)
      tree.update(site)
    end
    assert_equal 2, warnings.size, warnings.inspect
    assert_equal 1, tree.find("/midpoint/").subnodes.count { |n| n.url == "/about/writing/" }
  end

  def test_alias_before_parent_indexed
    assert_equal "/about/writing/", ALIAS_PAGES.keys[1]
    assert_equal "/midpoint/", @tree.find("/midpoint/writing/").parent.url
  end
end
