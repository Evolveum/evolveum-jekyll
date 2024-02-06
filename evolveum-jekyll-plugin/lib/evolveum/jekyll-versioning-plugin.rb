# This plugin is used to download and prepare versioning environment.
# It downloads multiple branches of midpoint repository based on docsBranch property of mp versions described in midpoint-versions.yaml file.
# Then creates symlinks in docs repository leading to individiual versions of cloned mp repositories

require 'yaml'

#$stdout.reopen("/var/log/jekylversioning", "w")

def installVersions()
  arr = readVersions()
  versions = arr[0]
  displayVersions = arr[1]
  defaultBranch = arr[2]
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
  system("find /docs -mindepth 1 -not -path '*/[@.]*' -type f -exec perl -pi -e 's/xref:\\/midpoint\\/reference\\/(#{negativeAssert})/xrefv:\\/midpoint\\/reference\\/#{defaultBranch.gsub("docs/","")}\\//g' {} \\;")
  system("find /docs -mindepth 1 -not -path '*/[@.]*' -type f -exec perl -pi -e 's/midpoint\\/reference\\/(#{negativeAssert})/midpoint\\/reference\\/#{defaultBranch.gsub("docs/","")}\\//g' {} \\;")

  versions.each_with_index do |version, index|
    versionWithoutDocs = version.gsub("docs/","")
    if Dir["/mp-#{versionWithoutDocs}"].empty?
      `cd / && git clone -b #{version} https://github.com/janmederly/testversioning mp-#{versionWithoutDocs} && rm /mp-#{versionWithoutDocs}/docs/LICENSE` #maybe
      #system("sed -i 's/:page-nav-title: Configuration Reference/:page-nav-title: \"#{displayVersions[index]}\"/g' /mp-#{versionWithoutDocs}/docs/index.adoc")
      #system("find /mp-#{versionWithoutDocs}/docs -type f -exec perl -pi -e 's/midpoint\\/reference\\/(#{negativeAssert})/midpoint\\/reference\\/#{versionWithoutDocs}\\//g' {} \\;")
    end
    if version != defaultBranch
      `grep -rl :page-alias: /mp-#{versionWithoutDocs}/docs/ | xargs sed -i '/:page-alias:/d' 2> /dev/null || true`
    #else
    #  lines = File.readlines('/docs/_site/.htaccess')
    #  lines[0] = 'RewriteRule   "^midpoint/reference(?!/master)(?!/before-.*)(?![0-9]\..*)(?!/support-.*)(/|$)(.*)" "/midpoint/reference/' + versionWithoutDocs + '/$2" [R]' << $/
    #  File.open('/docs/_site/.htaccess', 'w') { |f| f.write(lines.join) }
    end
    `ln -s /mp-#{versionWithoutDocs}/docs/ /docs/midpoint/reference/#{versionWithoutDocs}`
    system("sed -i 's/:page-nav-title: Configuration Reference/:page-nav-title: \"#{displayVersions[index]}\"/g' /mp-#{versionWithoutDocs}/docs/index.adoc")
    system("find /mp-#{versionWithoutDocs}/docs -type f -exec perl -pi -e 's/xref:\\/midpoint\\/reference\\/(#{negativeAssert})/xrefv:\\/midpoint\\/reference\\/#{versionWithoutDocs}\\//g' {} \\;")
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
  #puts("OBJ" + verObject.inspect)
  filteredVersions = []
  filteredDisplayVersions = []
  defaultBranch = ""
  verObject.each do |ver|
    #puts(ver)
      if ver['docsBranch'] != nil && ver['docsDisplayBranch']
        puts("version" + ver['docsBranch'])
        filteredVersions.push(ver['docsBranch'])
        filteredDisplayVersions.push(ver['docsDisplayBranch'])
        puts ver['defaultBranch']
        if ver['defaultBranch'] != nil && ver['defaultBranch'] == true
          defaultBranch = ver['docsBranch']
        end
      end
  end
  if defaultBranch == ""
    defaultBranch = "master"
  end
  filteredVersions.push("docs/before-4.8")
  filteredDisplayVersions.push("4.7 and earlier")
  filteredVersions.push("master")
  filteredDisplayVersions.push("Development")
  return([filteredVersions, filteredDisplayVersions, defaultBranch])
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
  installVersions()
end
