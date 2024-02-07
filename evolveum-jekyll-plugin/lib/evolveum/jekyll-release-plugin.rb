
require 'yaml'

def installReleaseNotes()
  versions = readVersions()
  versions.each do |ver|
    `cd /docs/midpoint/release/ && mkdir #{ver} && cd #{ver} && wget https://raw.githubusercontent.com/Evolveum/midpoint/v#{ver}/release-notes.adoc
    && mv release-notes.adoc index.adoc && wget https://raw.githubusercontent.com/Evolveum/midpoint/v#{ver}/install-dist.adoc && mv install-dist.adoc install.adoc`
  end
end

def readVersions()
  verObject = YAML.load_file('/docs/_data/midpoint-versions.yml')
  versionsNumbers = []
  verObject.each do |ver|
    if (ver.version.to_d >= 4.8 && ver.status != "planned" && ver.status != "development")
      versionsNumbers.push(ver.version.to_d)
    end
  end
  return(versionsNumbers)
end

Jekyll::Hooks.register :site, :after_init do |site|
  puts "=========[ EVOLVEUM RELEASE NOTES INSTALL ]============== after_init"
  installReleaseNotes()
end
