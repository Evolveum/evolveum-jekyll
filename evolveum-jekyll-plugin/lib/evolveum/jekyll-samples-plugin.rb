
def installSamples(site)
  samplesDir = site.config['docs']['midpointSamplesPath'] + site.config['docs']['midpointSamplesDirName']
  if Dir[samplesDir].empty?
    system("cd #{site.config['docs']['midpointSamplesPath']} && git clone https://github.com/Evolveum/midpoint-samples/ #{site.config['docs']['midpointSamplesDirName']}")
  end
end

Jekyll::Hooks.register :site, :after_init do |site|
  puts "=========[ EVOLVEUM SAMPLES INSTALL ]============== after_init"
  installSamples(site)
end
