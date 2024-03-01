# This plugin is used to download and prepare versioning environment.
# It downloads multiple branches of midpoint repository based on docsBranch property of mp versions described in midpoint-versions.yaml file.
# Then creates symlinks in docs repository leading to individiual versions of cloned mp repositories

require 'yaml'

def installVersions(site)
  docsDir = site.config['docs']['docsPath'] + site.config['docs']['docsDirName']
  mpPreDir = site.config['docs']['midpointVersionsPath'] + site.config['docs']['midpointVersionsPrefix']
  arr = readVersions(docsDir)
  versions = arr[0]
  displayVersions = arr[1]
  defaultBranch = arr[2]
  system("rm -rf #{docsDir}/midpoint/reference/*")
  system("cp /mnt/index.html #{docsDir}/midpoint/reference/")
  negativeAssert = "?!(?:"
  versions.each do |version|
    versionWithoutDocs = version.gsub("docs/","")
    negativeAssert << "#{versionWithoutDocs}|"
    puts("?!#{versionWithoutDocs}|")
  end
  negativeAssert.chop!
  negativeAssert << ")"
  puts(negativeAssert)
  system("find #{docsDir} -mindepth 1 -not -path '*/[@.]*' -type f -exec perl -pi -e 's/xref:\\/midpoint\\/reference\\/(#{negativeAssert})/xrefv:\\/midpoint\\/reference\\/#{defaultBranch.gsub("docs/","")}\\//g' {} +")
  system("find #{docsDir} -mindepth 1 -not -path '*/[@.]*' -type f -exec perl -pi -e 's/midpoint\\/reference\\/(#{negativeAssert})/midpoint\\/reference\\/#{defaultBranch.gsub("docs/","")}\\//g' {} +")

  versions.each_with_index do |version, index|
    versionWithoutDocs = version.gsub("docs/","")
    if Dir["#{mpPreDir}#{versionWithoutDocs}"].empty?
      system("cd #{site.config['docs']['midpointVersionsPath']} && git clone -b #{version} https://github.com/janmederly/testversioning #{site.config['docs']['midpointVersionsPrefix']}#{versionWithoutDocs} && rm #{mpPreDir}#{versionWithoutDocs}/docs/LICENSE") #maybe
    end
    if version != defaultBranch
      system("grep -rl :page-alias: #{mpPreDir}#{versionWithoutDocs}/docs/ | xargs -P 4 sed -i '/:page-alias:/d' 2> /dev/null || true")
    end
    system("ln -s #{mpPreDir}#{versionWithoutDocs}/docs/ #{docsDir}/midpoint/reference/#{versionWithoutDocs}")
    system("sed -i 's/:page-nav-title: Configuration Reference/:page-nav-title: \"#{displayVersions[index]}\"/g' #{mpPreDir}#{versionWithoutDocs}/docs/index.adoc")
    system("find #{mpPreDir}#{versionWithoutDocs}/docs -type f -exec perl -pi -e 's/xref:\\/midpoint\\/reference\\/(#{negativeAssert})/xrefv:\\/midpoint\\/reference\\/#{versionWithoutDocs}\\//g' {} +")
    system("find #{mpPreDir}#{versionWithoutDocs}/docs -type f -exec perl -pi -e 's/midpoint\\/reference\\/(#{negativeAssert})/midpoint\\/reference\\/#{versionWithoutDocs}\\//g' {} +")
  end
end

def readVersions(docsDir)
  verObject = YAML.load_file("#{docsDir}/_data/midpoint-versions.yml")
  filteredVersions = []
  filteredDisplayVersions = []
  defaultBranch = ""
  verObject.each do |ver|
      if ver['docsBranch'] != nil && ver['docsDisplayBranch']
        #puts("version" + ver['docsBranch'])
        filteredVersions.push(ver['docsBranch'])
        filteredDisplayVersions.push(ver['docsDisplayBranch'])
        #puts ver['defaultBranch']
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

Jekyll::Hooks.register :site, :after_init do |site|
  puts "=========[ EVOLVEUM VERSIONNING ]============== after_init"
  installVersions(site)
end
