
require 'yaml'

def installReleaseNotes()
  returnedVerArr = readReleaseVersions()
  versions = returnedVerArr[0]
  versionsReleaseBranches = returnedVerArr[1]
  versions.each_with_index do |ver, index|
    if Dir["/docs/midpoint/release/#{ver}"].empty?
      `cd /docs/midpoint/release/ && mkdir #{ver}`
    end

    if (!File.exist?("/docs/midpoint/release/#{ver}/index.adoc"))
      `cd /docs/midpoint/release/#{ver}/ && wget -q https://raw.githubusercontent.com/Evolveum/midpoint/#{versionsReleaseBranches[index]}/release-notes.adoc && mv release-notes.adoc index.adoc`
    end

    if (!File.exist?("/docs/midpoint/release/#{ver}/install.adoc"))
      `cd /docs/midpoint/release/#{ver}/ && wget -q https://raw.githubusercontent.com/Evolveum/midpoint/#{versionsReleaseBranches[index]}/install-dist.adoc && mv install-dist.adoc install.adoc`
    end
  end
end

def readReleaseVersions()
  verObject = YAML.load_file('/docs/_data/midpoint-versions.yml')
  versionsNumbers = []
  versionBranches = []
  verObject.each do |ver|
    if ((!ver.key?("legacyDocs") || ver["legacyDocs"] != true ))
      versionsNumbers.push(ver["version"].to_f)
      if (ver["docsReleaseBranch"] != nil)
        versionBranches.push(ver["docsReleaseBranch"])
      else
        versionBranches.push("master")
      end
    end
  end
  return(versionsNumbers, versionBranches)
end

Jekyll::Hooks.register :site, :after_init do |site|
  puts "=========[ EVOLVEUM RELEASE NOTES INSTALL ]============== after_init"
  installReleaseNotes()
end
