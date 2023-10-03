require 'yaml'

def installVersions(versions)
  if Dir["/mp-#{versions[0]}"].empty?
    `mv /docs/midpoint/reference/index.adoc /`
    `rm -rf /docs/midpoint/reference/*`
    `cp /mnt/index.html /docs/midpoint/reference/`
    system("cd /docs && grep -rl midpoint/reference . | xargs sed -i '/reference\\/master/!s/midpoint\\/reference/midpoint\\/reference\\/master/'")
  end

  versions.each do |version|
    if Dir["/mp-#{version}"].empty?
      `cd / && git clone -b #{version} https://github.com/janmederly/testversioning mp-#{version} && rm /mp-#{version}/docs/LICENSE && mkdir -p /docs/midpoint/reference/#{version} && mv /mp-#{version}/docs/* /docs/midpoint/reference/#{version}/ && cp /index.adoc /docs/midpoint/reference/#{version}/` #maybe
      if version != "master"
        `grep -rl :page-alias: /docs/midpoint/reference/#{version}/ | xargs sed -i '/:page-alias:/d'`
      end
    end
  end
end

verObject = YAML.load_file('/docs/_data/midpoint-versions.yml')
puts("OBJ" + verObject.inspect)
filteredVersions = []
verObject.each do |ver|
  puts(ver)
    if ver['docsBranch'] != nil
      puts("version" + ver['docsBranch'])
      filteredVersions.push(ver['docsBranch'])
    end
end
installVersions(filteredVersions)
