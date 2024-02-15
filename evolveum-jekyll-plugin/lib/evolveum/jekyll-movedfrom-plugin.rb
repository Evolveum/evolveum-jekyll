Jekyll::Hooks.register :pages, :post_init do |page|
  if (page.data['moved-from'] != nil)
    File.write('/testMovedFrom', page.data['moved-from'], mode: 'a')
  elsif (page.data['page-moved-from'] != nil)
    File.write('/testMovedFrom', page.data['page-moved-from'], mode: 'a')
  end
end
