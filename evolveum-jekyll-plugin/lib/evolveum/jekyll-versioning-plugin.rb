# This plugin is used to download and prepare versioning environment.
# It downloads multiple branches of midpoint repository based on docsBranch property of mp versions described in midpoint-versions.yaml file.
# Then creates symlinks in docs repository leading to individiual versions of cloned mp repositories

require 'yaml'

#$stdout.reopen("/var/log/jekylversioning", "w")

def installVersions(versions, displayVersions)
    #`mv /docs/midpoint/reference/index.adoc /`
  `rm -rf /docs/midpoint/reference/*`
  `cp /mnt/index.html /docs/midpoint/reference/`
  negativeAssert = "?!(?:"
  versions.each do |version|
    versionWithoutDocs = version.gsub("docs/","")
    negativeAssert << "#{versionWithoutDocs}|"
    puts("?!#{versionWithoutDocs}|")
  end
  negativeAssert.chop!
  negativeAssert << ")"
  puts(negativeAssert)
  system("find /docs -mindepth 1 -not -path '*/[@.]*' -type f -exec perl -pi -e 's/midpoint\\/reference\\/(#{negativeAssert})/midpoint\\/reference\\/master\\//g' {} \\;")

  versions.each_with_index do |version, index|
    versionWithoutDocs = version.gsub("docs/","")
    if Dir["/mp-#{versionWithoutDocs}"].empty?
      `cd / && git clone -b #{version} https://github.com/janmederly/testversioning mp-#{versionWithoutDocs} && rm /mp-#{versionWithoutDocs}/docs/LICENSE` #maybe
      #system("sed -i 's/:page-nav-title: Configuration Reference/:page-nav-title: \"#{displayVersions[index]}\"/g' /mp-#{versionWithoutDocs}/docs/index.adoc")
      #system("find /mp-#{versionWithoutDocs}/docs -type f -exec perl -pi -e 's/midpoint\\/reference\\/(#{negativeAssert})/midpoint\\/reference\\/#{versionWithoutDocs}\\//g' {} \\;")
    end
    if version != "master"
      `grep -rl :page-alias: /mp-#{versionWithoutDocs}/docs/ | xargs sed -i '/:page-alias:/d'`
    end
    `ln -s /mp-#{versionWithoutDocs}/docs/ /docs/midpoint/reference/#{versionWithoutDocs}`
    #system("sed -i 's/:page-nav-title: Configuration Reference/:page-nav-title: \"#{displayVersions[index]}\"/g' /mp-#{versionWithoutDocs}/docs/index.adoc")
    system("find /mp-#{versionWithoutDocs}/docs -type f -exec perl -pi -e 's/midpoint\\/reference\\/(#{negativeAssert})/midpoint\\/reference\\/#{versionWithoutDocs}\\//g' {} \\;")
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
  filteredDisplayVersions = []
  verObject.each do |ver|
    puts(ver)
      if ver['docsBranch'] != nil && ver['docsDisplayBranch']
        puts("version" + ver['docsBranch'])
        upVer = ver['docsBranch'].gsub("/", "FWDS")
        filteredVersions.push(ver['docsBranch'])
        filteredDisplayVersions.push(ver['docsDisplayBranch'])
      end
  end
  filteredVersions.push("docs/before-4.8")
  filteredDisplayVersions.push("4.7 and earlier")
  filteredVersions.push("master")
  filteredDisplayVersions.push("Development")
  installVersions(filteredVersions, filteredDisplayVersions)
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
