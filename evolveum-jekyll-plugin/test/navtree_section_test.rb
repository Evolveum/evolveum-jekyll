require_relative "test_helper"
require_relative "fixtures"

class NavtreeSectionTest < Minitest::Test
  PAGES = SECTION_PAGES.merge(
    "/midpoint/secret/" => { "title" => "Secret", "visibility" => "hidden" }
  ).freeze

  def setup
    @tree = build_tree(PAGES)
  end

  def render(url)
    render_tag("navtree", @tree, url, SECTION_CONFIG)
  end

  def assert_top_level_list(html)
    assert_includes html, 'href="/iam/"'
    assert_includes html, 'href="/midpoint/"'
    refute_includes html, 'href="/midpoint/guides/"'
    refute_includes html, "ev-sidebar-title"
  end

  HOME_LINK = '<p class="ev-sidebar-home"><a href="/"><i class="fa-solid fa-house" aria-hidden="true"></i>Documentation home</a></p>'

  def test_scoped_starts_with_home_link
    assert render("/midpoint/guides/a/").start_with?(HOME_LINK)
  end

  def test_home_link_on_section_root
    assert render("/midpoint/").start_with?(HOME_LINK)
  end

  def test_no_home_link_in_top_level_list
    refute_includes render("/"), "ev-sidebar-home"
    refute_includes render("/legal/terms/"), "ev-sidebar-home"
  end

  def test_scoped_excludes_other_sections
    refute_includes render("/midpoint/guides/a/"), 'href="/iam/"'
  end

  def test_scoped_title
    assert_includes render("/midpoint/guides/a/"),
      '<p class="ev-sidebar-title" id="navtree-title"><a href="/midpoint/">MidPoint</a></p>'
  end

  def test_scoped_root_not_list_item
    refute_includes render("/midpoint/guides/a/"), '<li><a href="/midpoint/">'
  end

  def test_scoped_siblings_and_active
    html = render("/midpoint/guides/a/")
    assert_includes html, 'href="/midpoint/release/"'
    assert_includes html, '<li class="active"><a href="/midpoint/guides/a/" aria-current="page">A</a>'
    refute_includes html, 'href="/midpoint/guides/b/"'
  end

  def test_scoped_root_page
    html = render("/midpoint/")
    assert_includes html, '<p class="ev-sidebar-title" id="navtree-title"><a href="/midpoint/" aria-current="page">MidPoint</a></p>'
    assert_includes html, 'href="/midpoint/guides/"'
    assert_includes html, 'href="/midpoint/release/"'
  end

  def test_nested_section
    html = render("/midpoint/reference/master/")
    assert_includes html, '<p class="ev-sidebar-title" id="navtree-title"><a href="/midpoint/reference/">Reference</a></p>'
    refute_includes html, 'href="/midpoint/guides/"'
  end

  def test_hidden_page_under_root_shows_first_level
    html = render("/midpoint/secret/")
    assert_includes html, "ev-sidebar-title"
    assert_includes html, 'href="/midpoint/guides/"'
    assert_includes html, 'href="/midpoint/release/"'
    refute_includes html, 'href="/midpoint/secret/"'
  end

  def test_hidden_section_top_level_list
    assert_top_level_list render("/legal/terms/")
  end

  def test_home_top_level_list
    assert_top_level_list render("/")
  end

  def test_404_top_level_list
    assert_top_level_list render("/404.html")
  end

  def test_unknown_url_top_level_list
    assert_top_level_list render("/not/in/tree/")
  end

  def test_title_entities_not_double_escaped
    tree = build_tree({
      "/qa/" => { "title" => "Q&amp;A" },
      "/qa/one/" => { "title" => "One" }
    })
    html = render_tag("navtree", tree, "/qa/one/", SECTION_CONFIG)
    assert_includes html, ">Q&amp;A</a></p>"
  end
end
