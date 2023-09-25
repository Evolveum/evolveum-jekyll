# This plugin is used to download and prepare versioning environment.
# It downloads multiple branches of midpoint repository based on docsBranch property of mp versions described in midpoint-versions.yaml file.
# Then creates symlinks in docs repository leading to individiual versions of cloned mp repositories
# Afterwards it creates content of mp version select for docs site

require 'yaml'

$stdout.reopen("/var/log/jekylversioning", "w")


def installVersions(versions)
  versions.each do |version|
    IO.popen("cd / && git clone -b #{version} https://github.com/janmederly/testversioning mp-#{version} && ln -s /mp-#{version}/docs/ /docs/midpoint/reference/#{version}") #maybe mkdir
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
