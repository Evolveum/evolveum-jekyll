# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "evolveum-jekyll-theme"
  spec.version       = "0.1.0"
  spec.authors       = ["Radovan Semancik"]
  spec.email         = ["radovan.semancik@evolveum.com"]

  spec.summary       = "Evolveum theme"
  spec.homepage      = "https://evolveum.com/"
  spec.license       = "Nonstandard"

  spec.files         = `git ls-files -z`.split("\x0").select { |f| f.match(%r!^(assets|_layouts|_includes|_sass|LICENSE|README|_config\.yml)!i) }

  spec.add_runtime_dependency "jekyll", "~> 4.1"
end
