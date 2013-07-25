# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "omniauth-bcom/version"

Gem::Specification.new do |spec|
  spec.name          = "omniauth-bcom"
  spec.version       = Omniauth::Bcom::VERSION
  spec.authors       = ["Eugene Correia"]
  spec.email         = ["ecorreia@blueskybroadcast.com"]
  spec.description   = %q{B-Com Omniauth Gem}
  spec.summary       = %q{B-Com Ominauth gem using oauth2 specs}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'omniauth', '~> 1.0'
  spec.add_dependency 'omniauth-oauth2', '~> 1.0'
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
