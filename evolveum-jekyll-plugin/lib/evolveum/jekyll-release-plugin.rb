
require 'yaml'
require 'open3'

def readReleaseVersions(docsDir)
  verObject = YAML.load_file("#{docsDir}/_data/midpoint-versions.yml")
  versionsNumbers = []
  versionBranches = []
  docsBranches = []
  verObject.each do |ver|
    if ver['docsBranch'] != nil && ver['docsDisplayBranch']
      docsBranches.push(ver['docsBranch'])
    end
    if ((!ver.key?("legacyDocs") || ver["legacyDocs"] != true ))
      if (ver["docsReleaseBranch"] != nil)
        versionBranches.push(ver["docsReleaseBranch"])
        versionsNumbers.push(ver["version"])
      end
    end
  end
  docsBranches.push("docs/before-4.8")
  docsBranches.push("master")
  return versionsNumbers, versionBranches, docsBranches
end

def installReleaseNotes(site)
  docsDir = site.config['docs']['docsPath'] + site.config['docs']['docsDirName']
  releaseDir = site.config['docs']['midpointReleasePath'] + site.config['docs']['midpointReleaseDir']
  mpRepo = site.config['environment']['midpointRepositoryGhName']
  returnedVerArr = readReleaseVersions(docsDir)
  versions = returnedVerArr[0]
  versionsReleaseBranches = returnedVerArr[1]
  docsBranches = returnedVerArr[2]
  addedSlash = "/"
  if (site.config['docs']['docsPath'] == "/")
    addedSlash = ""
  end
  versions.each_with_index do |ver, index|
    puts("ver " + ver + " index " + index.to_s + " releaseBranch " + versionsReleaseBranches[index] + " docsBranches " + docsBranches.join(" "))

    if Dir["#{docsDir}/midpoint/release/#{ver}"].empty?
      system("cd #{docsDir}/midpoint/release/ && mkdir #{ver}")
    end

    if (!docsBranches.include?(versionsReleaseBranches[index]))
      if !Dir.exist?("#{releaseDir}/#{ver}")
        Jekyll.logger.info("DIR: #{releaseDir}/#{ver} does not exist, creating...")
        system("cd #{site.config['docs']['midpointReleasePath']} && mkdir -p #{site.config['docs']['midpointReleaseDir']}/#{ver}")
      end

      #if (!File.exist?("#{releaseDir}/#{ver}/index.adoc"))
        system("ls && echo #{releaseDir} && cd #{releaseDir} && ls && cd #{ver}/ && wget -q https://raw.githubusercontent.com/#{mpRepo}/#{versionsReleaseBranches[index]}/release-notes.adoc && mv release-notes.adoc index.adoc")
      #end
      releaseInode = File.stat("#{releaseDir}/#{ver}/index.adoc").ino

      #if (!File.exist?("#{releaseDir}/#{ver}/install.adoc"))
        system("ls && echo #{releaseDir} && cd #{releaseDir} && ls && cd #{ver}/ && wget -q https://raw.githubusercontent.com/#{mpRepo}/#{versionsReleaseBranches[index]}/install-dist.adoc && mv install-dist.adoc install.adoc")
      #end
      installInode = File.stat("#{releaseDir}/#{ver}/install.adoc").ino

    else
      releaseInode = File.stat("#{site.config['docs']['midpointVersionsPath']}#{site.config['docs']['midpointVersionsPrefix']}#{versionsReleaseBranches[index].gsub("docs/","").gsub("/", "__SLASH__")}/release-notes.adoc").ino
      installInode = File.stat("#{site.config['docs']['midpointVersionsPath']}#{site.config['docs']['midpointVersionsPrefix']}#{versionsReleaseBranches[index].gsub("docs/","").gsub("/", "__SLASH__")}/install-dist.adoc").ino
    end

    if (!File.exist?("#{docsDir}/midpoint/release/#{ver}/index.adoc"))
      if (docsBranches.include?(versionsReleaseBranches[index]))
        system("ACTPATH=$PWD && cd #{site.config['docs']['docsPath']} && DOCSPATHVAR=$PWD && cd $ACTPATH && cd #{site.config['docs']['midpointVersionsPath']} && ln -s \"$PWD\"/#{site.config['docs']['midpointVersionsPrefix']}#{versionsReleaseBranches[index].gsub("docs/","").gsub("/", "__SLASH__")}/release-notes.adoc \"$DOCSPATHVAR\"#{addedSlash}#{site.config['docs']['docsDirName']}/midpoint/release/#{ver}/index.adoc")
      else
        system("ACTPATH=$PWD && cd #{site.config['docs']['docsPath']} && DOCSPATHVAR=$PWD && cd $ACTPATH && cd #{site.config['docs']['midpointReleasePath']} && ln -s \"$PWD\"/#{site.config['docs']['midpointReleaseDir']}/#{ver}/index.adoc \"$DOCSPATHVAR\"#{addedSlash}#{site.config['docs']['docsDirName']}/midpoint/release/#{ver}/index.adoc")
      end
    else
      output, _ = Open3.capture2("cd #{docsDir}/midpoint/release/#{ver}/ && ls -F index.adoc")
      if (!output.include?("index.adoc@"))
        if (docsBranches.include?(versionsReleaseBranches[index]))
          # DOES THIS WORK?????
          system("cp -f #{site.config['docs']['midpointVersionsPath'] + site.config['docs']['midpointVersionsPrefix'] + versionsReleaseBranches[index].gsub("docs/","")}/release-notes.adoc #{docsDir}/midpoint/release/#{ver}/ && cd #{docsDir}/midpoint/release/#{ver}/ && mv release-notes.adoc index.adoc")
        else
          system("cp -f #{releaseDir}/#{ver}/index.adoc #{docsDir}/midpoint/release/#{ver}/")
        end
        Jekyll.logger.warn("Unexpexted index.adoc file in /midpoint/release/#{ver}/, replacing with release notes from midPoint repository.")
      else
        releaseInodeNew = File.stat("#{docsDir}/midpoint/release/#{ver}/index.adoc").ino
        if (releaseInodeNew != releaseInode)
          Jekyll.logger.warn("index.adoc file in /midpoint/release/#{ver}/ changed original location, updating symlink")
          system("cd #{docsDir}/midpoint/release/#{ver}/ && rm -f index.adoc")
          if (docsBranches.include?(versionsReleaseBranches[index]))
            system("ACTPATH=$PWD && cd #{site.config['docs']['docsPath']} && DOCSPATHVAR=$PWD && cd $ACTPATH && cd #{site.config['docs']['midpointVersionsPath']} && ln -s \"$PWD\"/#{site.config['docs']['midpointVersionsPrefix']}#{versionsReleaseBranches[index].gsub("docs/","").gsub("/", "__SLASH__")}/release-notes.adoc \"$DOCSPATHVAR\"#{addedSlash}#{site.config['docs']['docsDirName']}/midpoint/release/#{ver}/index.adoc")
          else
            system("ACTPATH=$PWD && cd #{site.config['docs']['docsPath']} && DOCSPATHVAR=$PWD && cd $ACTPATH && cd #{site.config['docs']['midpointReleasePath']} && ln -s \"$PWD\"/#{site.config['docs']['midpointReleaseDir']}/#{ver}/index.adoc \"$DOCSPATHVAR\"#{addedSlash}#{site.config['docs']['docsDirName']}/midpoint/release/#{ver}/index.adoc")
          end
        end
      end
    end

    if (!File.exist?("#{docsDir}/midpoint/release/#{ver}/install.adoc"))
      if (docsBranches.include?(versionsReleaseBranches[index]))
        system("ACTPATH=$PWD && cd #{site.config['docs']['docsPath']} && DOCSPATHVAR=$PWD && cd $ACTPATH && cd #{site.config['docs']['midpointVersionsPath']} && ln -s \"$PWD\"/#{site.config['docs']['midpointVersionsPrefix']}#{versionsReleaseBranches[index].gsub("docs/","").gsub("/", "__SLASH__")}/install-dist.adoc \"$DOCSPATHVAR\"#{addedSlash}#{site.config['docs']['docsDirName']}/midpoint/release/#{ver}/install.adoc")
      else
        system("ACTPATH=$PWD && cd #{site.config['docs']['docsPath']} && DOCSPATHVAR=$PWD && cd $ACTPATH && cd #{site.config['docs']['midpointReleasePath']} && ln -s \"$PWD\"/#{site.config['docs']['midpointReleaseDir']}/#{ver}/install.adoc \"$DOCSPATHVAR\"#{addedSlash}#{site.config['docs']['docsDirName']}/midpoint/release/#{ver}/install.adoc")
      end
    else
      output, _ = Open3.capture2("cd #{docsDir}/midpoint/release/#{ver}/ && ls -F install.adoc")
      if (!output.include?("install.adoc@"))
        if (docsBranches.include?(versionsReleaseBranches[index]))
          system("cp -f #{site.config['docs']['midpointVersionsPath'] + site.config['docs']['midpointVersionsPrefix'] + versionsReleaseBranches[index].gsub("docs/","")}/install-dist.adoc #{docsDir}/midpoint/release/#{ver}/ && cd #{docsDir}/midpoint/release/#{ver}/ && mv install-dist.adoc install.adoc")
        else
          system("cp -f #{releaseDir}/#{ver}/install.adoc #{docsDir}/midpoint/release/#{ver}/")
        end
        Jekyll.logger.warn("Unexpexted install.adoc file in /midpoint/release/#{ver}/, replacing with release notes from midPoint repository.")
      else
        installInodeNew = File.stat("#{docsDir}/midpoint/release/#{ver}/install.adoc").ino
        if (installInodeNew != installInode)
          Jekyll.logger.warn("install.adoc file in /midpoint/release/#{ver}/ changed original location, updating symlink")
          system("cd #{docsDir}/midpoint/release/#{ver}/ && rm -f install.adoc")
          if (docsBranches.include?(versionsReleaseBranches[index]))
            system("ACTPATH=$PWD && cd #{site.config['docs']['docsPath']} && DOCSPATHVAR=$PWD && cd $ACTPATH && cd #{site.config['docs']['midpointVersionsPath']} && ln -s \"$PWD\"/#{site.config['docs']['midpointVersionsPrefix']}#{versionsReleaseBranches[index].gsub("docs/","").gsub("/", "__SLASH__")}/install-dist.adoc \"$DOCSPATHVAR\"#{addedSlash}#{site.config['docs']['docsDirName']}/midpoint/release/#{ver}/install.adoc")
          else
            system("ACTPATH=$PWD && cd #{site.config['docs']['docsPath']} && DOCSPATHVAR=$PWD && cd $ACTPATH && cd #{site.config['docs']['midpointReleasePath']} && ln -s \"$PWD\"/#{site.config['docs']['midpointReleaseDir']}/#{ver}/install.adoc \"$DOCSPATHVAR\"#{addedSlash}#{site.config['docs']['docsDirName']}/midpoint/release/#{ver}/install.adoc")
          end
        end
      end
    end
  end
end

Jekyll::Hooks.register :site, :after_init do |site|
  puts "=========[ EVOLVEUM RELEASE NOTES INSTALL ]============== after_init"
  if site.config['environment']['name'].include?("docs")
    installReleaseNotes(site)
  end
end
