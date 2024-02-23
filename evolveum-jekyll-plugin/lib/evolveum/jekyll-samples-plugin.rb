
def installSamples
  if Dir["/mp-samples"].empty?
    `cd / && git clone https://github.com/Evolveum/midpoint-samples/`
  end
end

Jekyll::Hooks.register :site, :after_init do |site|
  puts "=========[ EVOLVEUM SAMPLES INSTALL ]============== after_init"
  installSamples()
end
