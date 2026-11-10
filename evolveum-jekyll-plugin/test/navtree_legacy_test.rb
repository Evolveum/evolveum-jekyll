require_relative "test_helper"
require_relative "fixtures"

class NavtreeLegacyTest < Minitest::Test
  def setup
    @tree = build_tree(BASE_PAGES)
  end

  def test_legacy_lists_all_top_level_sections
    html = render_tag("navtree", @tree, "/midpoint/guides/a/")
    assert_includes html, 'href="/iam/"'
    assert_includes html, 'href="/midpoint/"'
    refute_includes html, 'href="/legal/"'
    assert_includes html, '<li class="active"><a href="/midpoint/guides/a/" aria-current="page">A</a>'
  end

  def test_legacy_root_page_shows_children
    html = render_tag("navtree", @tree, "/midpoint/")
    assert_includes html, 'href="/midpoint/guides/"'
    assert_includes html, 'href="/midpoint/release/"'
  end

  def test_legacy_snapshot
    html = render_tag("navtree", @tree, "/midpoint/guides/a/")
    assert_equal LEGACY_SNAPSHOT, html
  end

  LEGACY_SNAPSHOT = <<-HTML
<ul>
  <li><a href="/iam/">Identity and Access Management</a></li>
  <li><a href="/midpoint/">MidPoint</a>      <ul>
        <li><a href="/midpoint/guides/">Guides</a>          <ul>
            <li class="active"><a href="/midpoint/guides/a/" aria-current="page">A</a></li>
          </ul>
        </li>
        <li><a href="/midpoint/release/">Releases</a>        </li>
      </ul>
  </li>
</ul>
  HTML
end
