# This plugin is used to download and prepare versioning environment.
# It downloads multiple branches of midpoint repository based on docsBranch property of mp versions described in midpoint-versions.yaml file.
# Then creates symlinks in docs repository leading to individiual versions of cloned mp repositories
# Afterwards it creates content of mp version select for docs site

$stdout.reopen("/var/log/jekylversioning", "w")


def installVersions(versions)
  @versions.each do |version|
    IO.popen("cd / && git clone -b #{version} https://github.com/janmederly/testversioning mp-#{version} && ln -s /mp-#{version} /docs/midpoint/reference/#{version}") #maybe mkdir
  end
end

def generateSwitchContent()
 #generates content for version select
end

def filterVersions(context)
  @versions = context['site']['data']['midpoint-versions']
  filteredVersions = []
  @versions.each do |ver|
      if ver['docsBranch'] != nil
          filteredVersions.push(ver['docsBranch'])
      end
  end
  installVersions(filterVersions)
end


Jekyll::Hooks.register :site, :post_read do |site|
  puts "=========[ EVOLVEUM VERSIONNING ]============== post_read"
  puts(site.to_s)
  puts(site.data.to_s)
  filterVersions(site)
end
