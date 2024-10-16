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
    versions = []
    @config['latestVersions'] = []
    @config['releaseDocsVerMap'] = {}
    @config['defaultBranch'] = ""
    @config['negativeLookAhead'] = "(?!(?:"
    @config['releaseBranchMap'] = {}
    actVer = 'before-4.8'
    verObject.each do |ver|
      versions.each_with_index do |version, index|
        if (ver["status"] == "released" && ver["version"].to_s.include?(version))
          if (ver["version"].to_s.gsub("\.", "").to_i > @config['latestVersions'][index].gsub("\.", "").to_i)
            @config['latestVersions'][index] = ver['version'].to_s
            #@config['releaseDocsVerMap'][ver['version']] = actVer
          end
        end
      end
      if ver['docsBranch'] != nil && ver['docsDisplayBranch']
        #puts("version" + ver['docsBranch'])
        versions.push(ver['version'].to_s)
        @config['releaseDocsVerMap'][ver['version'].to_s] = ver['docsBranch']
        @config['latestVersions'].push(ver['version'].to_s)
        @config['filteredVersions'].push(ver['docsBranch'])
        @config['filteredVersionsWhDocs'].push(ver['docsBranch'].gsub("docs/",""))
        @config['filteredDisplayVersions'].push(ver['docsDisplayBranch'])
        @config['negativeLookAhead'] << "#{ver['docsBranch'].gsub("docs/","")}|"
        #puts ver['defaultBranch']
        if ver['defaultBranch'] != nil && ver['defaultBranch'] == true
          @config['defaultBranch'] = ver['docsBranch']
        end
        actVer = ver['docsBranch']
      end
      if (ver["type"] == "production" && ( ver["status"] == "planned" || ver["status"] == "development"))
        actVer = "master"
      elsif (actVer != 'before-4.8' && ver["type"] == "production" && ver["docsBranch"] == nil)
        actVer = "master"
      end
      if ver['docsReleaseBranch'] != nil
        @config['releaseBranchMap'][ver['version'].to_s] = ver['docsReleaseBranch']
      end
      # TODO - for now it works but there should be a check if the versions are in the correct order
      @config['releaseDocsVerMap'][ver['version'].to_s] = actVer
    end
    if @config['defaultBranch'] == ""
      @config['defaultBranch'] = "master"
    end
    @config['negativeLookAhead'] << "before-4.8|"
    @config['negativeLookAhead'] << "master|"
    @config['negativeLookAhead'].chop!
    @config['negativeLookAhead'] << "))"
    @config['filteredVersions'].push("docs/before-4.8")
    @config['filteredVersionsWhDocs'].push("before-4.8")
    @config['filteredDisplayVersions'].push("4.7 and earlier")
    @config['latestVersions'].push("4.7.4")
    @config['filteredVersions'].push("master")
    @config['filteredDisplayVersions'].push("Development")
    @config['filteredVersionsWhDocs'].push("master")
    @config['latestVersions'].push("master")
  end

  def self.get_config_value(key)
    @config[key]
  end
end

def installVersions(site)
  docsDir = site.config['docs']['docsPath'] + site.config['docs']['docsDirName']
  mpPreDir = site.config['docs']['midpointVersionsPath'] + site.config['docs']['midpointVersionsPrefix']
  mpRepo = site.config['environment']['midpointRepositoryGhName']
  VersionReader.load_config(docsDir)
  #arr = readVersions(docsDir)
  #versions = arr[0]
  #displayVersions = arr[1]
  #defaultBranch = arr[2]
  system("rm -rf #{docsDir}/midpoint/reference/*")

  if !Dir.exist?("#{docsDir}/midpoint/reference")
    system("mkdir #{docsDir}/midpoint/reference")
  end

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
      system("cd #{site.config['docs']['midpointVersionsPath']} && git clone -b #{version} https://github.com/#{mpRepo} #{site.config['docs']['midpointVersionsPrefix']}#{versionWithoutDocs}") #maybe && rm #{mpPreDir}#{versionWithoutDocs}/docs/LICENSE"
    end
    #if version != VersionReader.get_config_value('defaultBranch')
    # system("grep -rl :page-alias: #{mpPreDir}#{versionWithoutDocs}/docs/ | xargs -P 4 sed -i '/:page-alias:/d' 2> /dev/null || true")
    #end
    if (site.config['docs']['docsPath'] == "/")
      system("ACTPATH=$PWD && cd #{site.config['docs']['docsPath']} && DOCSPATHVAR=$PWD && cd $ACTPATH && cd #{site.config['docs']['midpointVersionsPath']} && ln -s \"$PWD\"/#{site.config['docs']['midpointVersionsPrefix']}#{versionWithoutDocs}/docs/ \"$DOCSPATHVAR\"#{site.config['docs']['docsDirName']}/midpoint/reference/#{versionWithoutDocs}")
    else
      system("ACTPATH=$PWD && cd #{site.config['docs']['docsPath']} && DOCSPATHVAR=$PWD && cd $ACTPATH && cd #{site.config['docs']['midpointVersionsPath']} && ln -s \"$PWD\"/#{site.config['docs']['midpointVersionsPrefix']}#{versionWithoutDocs}/docs/ \"$DOCSPATHVAR\"/#{site.config['docs']['docsDirName']}/midpoint/reference/#{versionWithoutDocs}")
    end
        #system("sed -i 's/:page-nav-title: Configuration Reference/:page-nav-title: \"#{VersionReader.get_config_value('filteredDisplayVersions')[index]}\"/g' #{mpPreDir}#{versionWithoutDocs}/docs/index.adoc")
    #system("find #{mpPreDir}#{versionWithoutDocs}/docs -type f -exec perl -pi -e 's/xref:\\/midpoint\\/reference\\/(#{negativeAssert})/xrefv:\\/midpoint\\/reference\\/#{versionWithoutDocs}\\//g' {} +")
    #system("find #{mpPreDir}#{versionWithoutDocs}/docs -type f -exec perl -pi -e 's/midpoint\\/reference\\/(#{negativeAssert})/midpoint\\/reference\\/#{versionWithoutDocs}\\//g' {} +")
  end
end

def setupPathVerData(page)
  ver = page.path.split("/")[2]
  versionsWhDocs = VersionReader.get_config_value('filteredVersionsWhDocs')
  versions = VersionReader.get_config_value('filteredVersions')
  displayVersions = VersionReader.get_config_value('filteredDisplayVersions')
  index = versionsWhDocs.find_index(ver)
  page.data['midpointBranch'] = versions[index]
  page.data['midpointBranchSlug'] = versionsWhDocs[index]
  page.data['midpointBranchDisplayName'] = displayVersions[index]
  page.data['midpointVersion'] = VersionReader.get_config_value('latestVersions')[index]
end

Jekyll::Hooks.register :site, :after_init do |site|
  puts "=========[ EVOLVEUM VERSIONING ]============== after_init"
  if site.config['environment']['name'].include?("docs")
    installVersions(site)
    Jekyll::Hooks.register :pages, :post_init do |page|
      if (page.path.include?("midpoint/reference/") && page.path != "midpoint/reference/index.html")
        setupPathVerData(page)
      end
      if (page.path.include?("midpoint/release/") && page.path != "midpoint/release/index.html")
        page.data['midpointVersion'] = page.path.split("/")[2]
        page.data['docsReleaseBranch'] = VersionReader.get_config_value('releaseBranchMap')[page.data['midpointVersion']]
      end
    end
  end
end
