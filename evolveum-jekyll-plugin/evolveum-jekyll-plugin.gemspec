# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jekyll-sitemap/version"

Gem::Specification.new do |spec|
  spec.name        = "evolveum-jekyll-plugin"
  spec.summary     = "Plugins for Jekyll theme."
  spec.version     = "0.1.0"
  spec.authors     = ["Evolveum"]
  spec.email       = "support@evolveum.com"
  spec.homepage    = "https://evolveum.com/"
  spec.licenses    = ["Nonstandard"]

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r!^bin/!) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r!^(test|spec|features)/!)
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.3.0"

  spec.add_dependency "jekyll", ">= 3.7", "< 5.0"
end
