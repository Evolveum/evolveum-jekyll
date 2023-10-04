# This plugin is used to download and prepare versioning environment.
# It downloads multiple branches of midpoint repository based on docsBranch property of mp versions described in midpoint-versions.yaml file.
# Then creates symlinks in docs repository leading to individiual versions of cloned mp repositories
# Afterwards it creates content of mp version select for docs site

require 'yaml'

$stdout.reopen("/var/log/jekylversioning", "w")

def installVersions(versions)
  if Dir["/mp-#{versions[0]}"].empty?
    `mv /docs/midpoint/reference/index.adoc /`
    `rm -rf /docs/midpoint/reference/*`
    `cp /mnt/index.html /docs/midpoint/reference/`
    system("cd /docs && find . -type f -exec perl -pi -e 's/midpoint\/reference\/(?!master\b)/midpoint\/reference\/master\//g' {} \;")
  end

  versions.each do |version|
    if Dir["/mp-#{version}"].empty?
      `cd / && git clone -b #{version} https://github.com/janmederly/testversioning mp-#{version} && rm /mp-#{version}/docs/LICENSE && mkdir -p /docs/midpoint/reference/#{version} && mv /mp-#{version}/docs/* /docs/midpoint/reference/#{version}/ && cp /index.adoc /docs/midpoint/reference/#{version}/` #maybe
      if version != "master"
        `grep -rl :page-alias: /docs/midpoint/reference/#{version}/ | xargs sed -i '/:page-alias:/d'`
      end
      `cd /docs/midpoint/reference/#{version}/ && find . -type f -exec perl -pi -e 's/midpoint\/reference\/(?!#{version}\b)/midpoint\/reference\/#{version}\//g' {} \;`
    end
  end
end

def generateSwitchContent()
 #generates content for version select
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

Jekyll::Hooks.register :site, :post_read do |site|
  puts "=========[ EVOLVEUM VERSIONNING ]============== post_read"
  generateSwitchContent()
end
