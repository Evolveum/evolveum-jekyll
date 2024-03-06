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
    @config['filteredVersionsWhDocs'] = []
    @config['defaultBranch'] = ""
    @config['negativeLookAhead'] = "(?!(?:"
    verObject.each do |ver|
      if ver['docsBranch'] != nil && ver['docsDisplayBranch']
        #puts("version" + ver['docsBranch'])
        @config['filteredVersions'].push(ver['docsBranch'])
        @config['filteredVersionsWhDocs'].push(ver['docsBranch'].gsub("docs/",""))
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
    @config['filteredVersionsWhDocs'].push("before-4.8")
    @config['filteredDisplayVersions'].push("4.7 and earlier")
    @config['filteredVersions'].push("master")
    @config['filteredDisplayVersions'].push("Development")
    @config['filteredVersionsWhDocs'].push("master")
  end

  def self.get_config_value(key)
    @config[key]
  end
end

def installVersions(site)
  docsDir = site.config['docs']['docsPath'] + site.config['docs']['docsDirName']
  mpPreDir = site.config['docs']['midpointVersionsPath'] + site.config['docs']['midpointVersionsPrefix']
  VersionReader.load_config(docsDir)
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

  VersionReader.get_config_value('filteredVersions').each_with_index do |version, index|
    versionWithoutDocs = version.gsub("docs/","")
    if Dir["#{mpPreDir}#{versionWithoutDocs}"].empty?
      system("cd #{site.config['docs']['midpointVersionsPath']} && git clone -b #{version} https://github.com/Evolveum/midpoint #{site.config['docs']['midpointVersionsPrefix']}#{versionWithoutDocs} && rm #{mpPreDir}#{versionWithoutDocs}/docs/LICENSE") #maybe
    end
    if version != VersionReader.get_config_value('defaultBranch')
     system("grep -rl :page-alias: #{mpPreDir}#{versionWithoutDocs}/docs/ | xargs -P 4 sed -i '/:page-alias:/d' 2> /dev/null || true")
    end
    system("cd #{site.config['docs']['midpointVersionsPath']} && ln -s \"$PWD\"/#{site.config['docs']['midpointVersionsPrefix']}#{versionWithoutDocs}/docs/ \"$PWD\"/#{site.config['docs']['docsDirName']}/midpoint/reference/#{versionWithoutDocs}")
    system("sed -i 's/:page-nav-title: Configuration Reference/:page-nav-title: \"#{VersionReader.get_config_value('filteredDisplayVersions')[index]}\"/g' #{mpPreDir}#{versionWithoutDocs}/docs/index.adoc")
  end
end

def setupPathVerData(page)
  ver = page.path.split("/")[2]
  versionsWhDocs = VersionReader.get_config_value('filteredVersionsWhDocs')
  versions = VersionReader.get_config_value('filteredVersions')
  displayVersions = VersionReader.get_config_value('filteredDisplayVersions')
  index = versionsWhDocs.find_index(ver)
  page.data['version'] = versions[index]
  page.data['versionWhDocs'] = versionsWhDocs[index]
  page.data['displayVersion'] = displayVersions[index]
end

Jekyll::Hooks.register :site, :after_init do |site|
  puts "=========[ EVOLVEUM VERSIONNING ]============== after_init"
  installVersions(site)
end

Jekyll::Hooks.register :pages, :post_init do |page|
  if (page.path.include?("midpoint/reference/") && page.path != "midpoint/reference/index.html")
    setupPathVerData(page)
  end
end
