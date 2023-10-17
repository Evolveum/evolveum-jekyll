# This plugin is used to download and prepare versioning environment.
# It downloads multiple branches of midpoint repository based on docsBranch property of mp versions described in midpoint-versions.yaml file.
# Then creates symlinks in docs repository leading to individiual versions of cloned mp repositories

require 'yaml'

#$stdout.reopen("/var/log/jekylversioning", "w")

def installVersions(versions)
  if Dir["/mp-#{versions[0]}"].empty?
    #`mv /docs/midpoint/reference/index.adoc /`
    `rm -rf /docs/midpoint/reference/*`
    `cp /mnt/index.html /docs/midpoint/reference/`
    system("find /docs -mindepth 1 -not -path '*/[@.]*' -type f -exec perl -pi -e 's/midpoint\\/reference\\/(?!master\\b)/midpoint\\/reference\\/master\\//g' {} \\;")
  end

  versions.each do |version|
    if Dir["/mp-#{version}"].empty?
      `cd / && git clone -b #{version} https://github.com/janmederly/testversioning mp-#{version} && rm /mp-#{version}/docs/LICENSE && ln -s /mp-#{version}/docs/ /docs/midpoint/reference/#{version}` #maybe
      if version != "master"
        `grep -rl :page-alias: /mp-#{version}/docs/ | xargs sed -i '/:page-alias:/d'`
      end
      system("sed -i 's/:page-nav-title: Configuration Reference/:page-nav-title: #{version.capitalize}/g' /mp-#{version}/docs/index.adoc")
      system("find /mp-#{version}/docs -type f -exec perl -pi -e 's/midpoint\\/reference\\/(?!#{version}\\b)/midpoint\\/reference\\/#{version}\\//g' {} \\;")
    end
  end
end

#def filterVersions(context)
#  @versions = context.data['midpoint-versions']
#  filteredVersions = []
#  @versions.each do |ver|
#    puts(ver)
#      if ver['docsBranch'] != nil
#        puts("version" + ver['docsBranch'])
#        filteredVersions.push(ver['docsBranch'])
#      end
#  end
#  installVersions(filteredVersions)
#end

def readVersions()
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
end

#def filterVersions(context)
#  @versions = context.data['midpoint-versions']
#  filteredVersions = []
#  @versions.each do |ver|
#    puts(ver)
#      if ver['docsBranch'] != nil
#        puts("version" + ver['docsBranch'])
#        filteredVersions.push(ver['docsBranch'])
#      end
#  end
#  installVersions(filteredVersions)
#end

Jekyll::Hooks.register :site, :after_init do |site|
  puts "=========[ EVOLVEUM VERSIONNING ]============== after_init"
  readVersions()
end
