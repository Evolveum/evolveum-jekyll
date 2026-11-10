require_relative "test_helper"
require_relative "fixtures"

class BreadcrumbsTest < Minitest::Test
  def setup
    @tree = build_tree(BASE_PAGES)
  end

  def test_breadcrumbs_home_in_section_mode
    html = render_tag("breadcrumbs", @tree, "/midpoint/guides/a/", SECTION_CONFIG)
    assert html.start_with?('<ol class="breadcrumb"><li class="breadcrumb-item"><a href="/">Home</a></li><li class="breadcrumb-item"><a href="/midpoint/">MidPoint</a></li>'), html
  end

  def test_breadcrumbs_legacy_unchanged
    html = render_tag("breadcrumbs", @tree, "/midpoint/guides/a/")
    assert html.start_with?('<ol class="breadcrumb"><li class="breadcrumb-item"><a href="/midpoint/">'), html
  end

  def test_breadcrumbs_root_page_current
    html = render_tag("breadcrumbs", @tree, "/midpoint/", SECTION_CONFIG)
    assert html.end_with?('<li class="breadcrumb-item"><a href="/midpoint/" aria-current="page">MidPoint</a></li></ol>'), html
  end
end

class StubReportTest < Minitest::Test
  def stub_site(config)
    site = build_site({ "/a/b/" => { "title" => "B" } }, config: config)
    tree = Evolveum::Nav.construct(site)
    tree.uninitializedStubs.each { |nav| nav.stub = true }
    site.data["nav"] = tree
    site
  end

  def test_stub_urls
    assert_equal ["/a"], stub_site({}).data["nav"].stub_urls
  end

  def test_report_stubs_off_by_default
    site = stub_site({})
    assert_empty capture_warnings { Evolveum::Nav.report_stubs(site) }
  end

  def test_report_stubs_on
    site = stub_site({ "navigation" => { "report-stubs" => true } })
    warnings = capture_warnings { Evolveum::Nav.report_stubs(site) }
    assert_equal 1, warnings.size
    assert_includes warnings.first, "/a"
  end
end
