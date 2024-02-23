
require 'yaml'

def installReleaseNotes()
  docsDir = site.config['docs']['docsPath'] + site.config['docs']['docsDirName']
  returnedVerArr = readReleaseVersions(docsDir)
  versions = returnedVerArr[0]
  versionsReleaseBranches = returnedVerArr[1]
  docsBranches = returnedVerArr[2]
  versions.each_with_index do |ver, index|
    puts("ver " + ver + " index " + index.to_s + " releaseBranch " + versionsReleaseBranches[index] + " docsBranches " + docsBranches.join(" "))
    if Dir["/docs/midpoint/release/#{ver}"].empty?
      `cd /docs/midpoint/release/ && mkdir #{ver}`
    end

    if (!File.exist?("/docs/midpoint/release/#{ver}/index.adoc"))
      if (docsBranches.include?(versionsReleaseBranches[index]))
        `ln -s /mp-#{versionsReleaseBranches[index].gsub("docs/","")}/release-notes-#{ver}.adoc /docs/midpoint/release/#{ver}/index.adoc`
      else
        `cd /docs/midpoint/release/#{ver}/ && wget -q https://raw.githubusercontent.com/Evolveum/midpoint/#{versionsReleaseBranches[index]}/release-notes-#{ver}.adoc && mv release-notes-#{ver}.adoc index.adoc`
      end
    end

    if (!File.exist?("/docs/midpoint/release/#{ver}/install.adoc"))
      if (docsBranches.include?(versionsReleaseBranches[index]))
        `ln -s /mp-#{versionsReleaseBranches[index].gsub("docs/","")}/install-dist-#{ver}.adoc /docs/midpoint/release/#{ver}/install.adoc`
      else
        `cd /docs/midpoint/release/#{ver}/ && wget -q https://raw.githubusercontent.com/Evolveum/midpoint/#{versionsReleaseBranches[index]}/install-dist-#{ver}.adoc && mv install-dist-#{ver}.adoc install.adoc`
      end
    end
  end
end

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
      versionsNumbers.push(ver["version"])
      if (ver["docsReleaseBranch"] != nil)
        versionBranches.push(ver["docsReleaseBranch"])
      else
        versionBranches.push("master")
      end
    end
  end
  docsBranches.push("docs/before-4.8")
  docsBranches.push("master")
  return versionsNumbers, versionBranches, docsBranches
end

Jekyll::Hooks.register :site, :after_init do |site|
  puts "=========[ EVOLVEUM RELEASE NOTES INSTALL ]============== after_init"
  installReleaseNotes(site)
end
