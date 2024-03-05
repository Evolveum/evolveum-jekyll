# This plugin is used to download and prepare versioning environment.
# It downloads multiple branches of midpoint repository based on docsBranch property of mp versions described in midpoint-versions.yaml file.
# Then creates symlinks in docs repository leading to individiual versions of cloned mp repositories

require 'yaml'

module VersionReader
  @config = {}

  def self.load_config(docsDir)
    verObject = YAML.load_file("#{docsDir}/_data/midpoint-versions.yml")
    @config['filteredVersions'] = []
    @config['filteredDisplayVersions'] = []
    @config['defaultBranch'] = ""
    @config['negativeLookAhead'] = "(?!(?:"
    verObject.each do |ver|
      if ver['docsBranch'] != nil && ver['docsDisplayBranch']
        #puts("version" + ver['docsBranch'])
        @config['filteredVersions'].push(ver['docsBranch'])
        @config['filteredDisplayVersions'].push(ver['docsDisplayBranch'])
        @config['negativeLookAhead'] << "#{ver['docsBranch'].gsub("docs/","")}|"
        #puts ver['defaultBranch']
        if ver['defaultBranch'] != nil && ver['defaultBranch'] == true
          @config['defaultBranch'] = ver['docsBranch']
        end
      end
    end
    if @config['defaultBranch'] == ""
      @config['defaultBranch'] = "master"
    end
    @config['negativeLookAhead'].chop!
    @config['negativeLookAhead'] << "))"
    @config['filteredVersions'].push("docs/before-4.8")
    @config['filteredDisplayVersions'].push("4.7 and earlier")
    @config['filteredVersions'].push("master")
    @config['filteredDisplayVersions'].push("Development")
  end

  def self.get_config_value(key)
    @config[key]
  end
end

def installVersions(site)
  docsDir = site.config['docs']['docsPath'] + site.config['docs']['docsDirName']
  mpPreDir = site.config['docs']['midpointVersionsPath'] + site.config['docs']['midpointVersionsPrefix']
  VersionReader.load_config(docsDir)
  #arr = readVersions(docsDir)
  #versions = arr[0]
  #displayVersions = arr[1]
  #defaultBranch = arr[2]
  system("rm -rf #{docsDir}/midpoint/reference/*")
  system("cp /mnt/index.html #{docsDir}/midpoint/reference/")
  negativeAssert = "?!(?:"
  VersionReader.get_config_value('filteredVersions').each do |version|
    versionWithoutDocs = version.gsub("docs/","")
    negativeAssert << "#{versionWithoutDocs}|"
    puts("?!#{versionWithoutDocs}|")
  end
  negativeAssert.chop!
  negativeAssert << ")"
  puts(negativeAssert)
  #system("find #{docsDir} -mindepth 1 -not -path '*/[@.]*' -type f -exec perl -pi -e 's/xref:\\/midpoint\\/reference\\/(#{negativeAssert})/xrefv:\\/midpoint\\/reference\\/#{VersionReader.get_config_value('defaultBranch').gsub("docs/","")}\\//g' {} +")
  #system("find #{docsDir} -mindepth 1 -not -path '*/[@.]*' -type f -exec perl -pi -e 's/midpoint\\/reference\\/(#{negativeAssert})/midpoint\\/reference\\/#{VersionReader.get_config_value('defaultBranch').gsub("docs/","")}\\//g' {} +")

  VersionReader.get_config_value('filteredVersions').each_with_index do |version, index|
    versionWithoutDocs = version.gsub("docs/","")
    if Dir["#{mpPreDir}#{versionWithoutDocs}"].empty?
      system("cd #{site.config['docs']['midpointVersionsPath']} && git clone -b #{version} https://github.com/janmederly/testversioning #{site.config['docs']['midpointVersionsPrefix']}#{versionWithoutDocs} && rm #{mpPreDir}#{versionWithoutDocs}/docs/LICENSE") #maybe
    end
    if version != VersionReader.get_config_value('defaultBranch')
     system("grep -rl :page-alias: #{mpPreDir}#{versionWithoutDocs}/docs/ | xargs -P 4 sed -i '/:page-alias:/d' 2> /dev/null || true")
    end
    system("cd #{site.config['docs']['midpointVersionsPath']} && ln -s \"$PWD\"/#{site.config['docs']['midpointVersionsPrefix']}#{versionWithoutDocs}/docs/ \"$PWD\"/#{site.config['docs']['docsDirName']}/midpoint/reference/#{versionWithoutDocs}")
    system("sed -i 's/:page-nav-title: Configuration Reference/:page-nav-title: \"#{VersionReader.get_config_value('filteredDisplayVersions')[index]}\"/g' #{mpPreDir}#{versionWithoutDocs}/docs/index.adoc")
    #system("find #{mpPreDir}#{versionWithoutDocs}/docs -type f -exec perl -pi -e 's/xref:\\/midpoint\\/reference\\/(#{negativeAssert})/xrefv:\\/midpoint\\/reference\\/#{versionWithoutDocs}\\//g' {} +")
    #system("find #{mpPreDir}#{versionWithoutDocs}/docs -type f -exec perl -pi -e 's/midpoint\\/reference\\/(#{negativeAssert})/midpoint\\/reference\\/#{versionWithoutDocs}\\//g' {} +")
  end
end

Jekyll::Hooks.register :site, :after_init do |site|
  puts "=========[ EVOLVEUM VERSIONNING ]============== after_init"
  installVersions(site)
end
