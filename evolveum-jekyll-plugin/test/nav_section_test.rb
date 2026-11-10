require_relative "test_helper"
require_relative "fixtures"

class NavSectionTest < Minitest::Test
  def setup
    @tree = build_tree(SECTION_PAGES, navbar: [{ "url" => "/midpoint/" }])
  end

  def test_section_root_falls_back_to_top_level
    assert_equal "/midpoint/", @tree.find("/midpoint/guides/a/").section_root.url
  end

  def test_section_root_nearest_flag_wins
    assert_equal "/midpoint/reference/", @tree.find("/midpoint/reference/master/").section_root.url
  end

  def test_section_root_of_root_page_is_itself
    assert_equal "/midpoint/", @tree.find("/midpoint/").section_root.url
  end

  def test_tree_root_has_no_section
    assert_nil @tree.section_root
  end

  def test_sidebar_root_nil_for_hidden_section
    assert_nil @tree.find("/legal/terms/").sidebar_root
  end

  def test_sidebar_root_nil_for_leaf_top_level
    assert_nil @tree.find("/404.html").sidebar_root
  end

  def test_page_data_written
    data = page_for(@tree, "/midpoint/guides/a/").data
    assert_equal "/midpoint/", data["nav_section_url"]
    assert_equal "MidPoint", data["nav_section_title"]
  end

  def test_page_data_nil_without_sidebar_root
    data = page_for(@tree, "/legal/terms/").data
    assert_nil data["nav_section_url"]
    assert_nil data["nav_section_title"]
  end

  def test_primary_url_deepest_prefix
    assert_equal "/midpoint/reference/",
      Evolveum::Nav.primary_url_for("/midpoint/reference/master/", ["/midpoint/", "/midpoint/reference/"])
  end

  def test_primary_url_segment_border
    assert_nil Evolveum::Nav.primary_url_for("/iam-foo/", ["/iam/"])
    assert_equal "/iam", Evolveum::Nav.primary_url_for("/iam/ldap/", ["/iam"])
  end

  def test_primary_url_no_match
    assert_nil Evolveum::Nav.primary_url_for("/book/", ["/iam/"])
  end

  def test_page_primary_url_written
    assert_equal "/midpoint/", page_for(@tree, "/midpoint/guides/a/").data["nav_primary_url"]
  end

  def test_section_mode
    assert Evolveum::Nav.section_mode?({ "navigation" => { "sidebar" => "section" } })
    refute Evolveum::Nav.section_mode?({})
    refute Evolveum::Nav.section_mode?({ "navigation" => nil })
    refute Evolveum::Nav.section_mode?({ "navigation" => { "sidebar" => "tree" } })
  end

  def test_section_mode_with_site_drop
    config = Jekyll.configuration(
      "quiet" => true,
      "source" => Dir.pwd,
      "destination" => Dir.mktmpdir,
      "environment" => { "name" => "test" },
      "navigation" => { "sidebar" => "section" }
    )
    site = Jekyll::Site.new(config)
    assert Evolveum::Nav.section_mode?(site.site_payload["site"])
    assert Evolveum::Nav.section_mode?(site)
  end

  def test_find_does_not_create_nodes
    count = @tree.subnodes.size
    assert_nil @tree.find("/nope/")
    assert_equal count, @tree.subnodes.size
  end
end
