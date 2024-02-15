Jekyll::Hooks.register :pages, :post_init do |page|
  if (page.data['moved-from'] != nil)
    File.write('/testMovedFrom', page.data['moved-from'], mode: 'a')
  end
end
