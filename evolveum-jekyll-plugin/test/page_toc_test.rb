require_relative "test_helper"
require "evolveum/jekyll-filters-plugin"

class PageTocTest < Minitest::Test
  def toc(html)
    Liquid::Template.parse("{{ html | page_toc }}").render!("html" => html)
  end

  def test_two_h2_render_toc
    html = toc('<h2 id="a">A</h2><p>x</p><h2 id="b">B</h2>')
    assert_includes html, '<nav class="ev-page-toc" aria-labelledby="ev-page-toc-title">'
    assert_includes html, '<h2 id="ev-page-toc-title" class="ev-aside__title">On this page</h2>'
    assert_operator html.index('<a href="#a">A</a>'), :<, html.index('<a href="#b">B</a>')
  end

  def test_h3_nested_under_h2
    html = toc('<h2 id="a">A</h2><h3 id="a1">A1</h3><h2 id="b">B</h2>')
    assert_includes html, '<li><a href="#a">A</a><ul><li><a href="#a1">A1</a></li></ul></li>'
  end

  def test_h3_before_h2_top_level
    html = toc('<h3 id="p">P</h3><h2 id="a">A</h2>')
    assert_includes html, '<ul><li><a href="#p">P</a></li><li><a href="#a">A</a></li></ul>'
  end

  def test_fewer_than_two_returns_empty
    assert_equal "", toc('<h2 id="a">A</h2>')
  end

  def test_headings_without_id_skipped
    html = toc('<h2>No</h2><h2 id="a">A</h2><h2 id="b">B</h2>')
    refute_includes html, "No"
  end

  def test_anchor_link_stripped
    html = toc('<h2 id="x"><a class="anchor" href="#x"></a>Title</h2><h2 id="y">Y</h2>')
    assert_includes html, '<a href="#x">Title</a>'
  end

  def test_inline_markup_stripped
    html = toc('<h2 id="x"><code>foo</code> bar</h2><h2 id="y">Y</h2>')
    assert_includes html, '<a href="#x">foo bar</a>'
  end

  def test_entities_kept
    html = toc('<h2 id="q">Q&amp;A</h2><h2 id="y">Y</h2>')
    assert_includes html, ">Q&amp;A</a>"
  end

  def test_special_ids_kept
    html = toc('<h2 id="_overview">O</h2><h2 id="4.10">V</h2>')
    assert_includes html, 'href="#_overview"'
    assert_includes html, 'href="#4.10"'
  end

  def test_h4_ignored
    html = toc('<h2 id="a">A</h2><h4 id="d">D</h4><h2 id="b">B</h2>')
    refute_includes html, 'href="#d"'
  end

  def test_heading_in_block_listed
    html = toc('<table><tr><td><h2 id="t">T</h2></td></tr></table><h2 id="u">U</h2>')
    assert_includes html, 'href="#t"'
    assert_includes html, 'href="#u"'
  end

  def test_attributes_before_id
    html = toc('<h2 class="x" id="a">A</h2><h2 id="b">B</h2>')
    assert_includes html, 'href="#a"'
  end
end
