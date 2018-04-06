
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "szmgmt/version"

Gem::Specification.new do |spec|
  spec.name          = "szmgmt"
  spec.version       = SZMGMT::VERSION
  spec.authors       = ["Tomas Simacek"]
  spec.email         = ["simacektomas@volny.cz"]

  spec.summary       = %q{Gem providing ruby library for management of Solaris zones.}
  spec.description   = %q{This gem supporst management of Oracle Solaris zones. It provides function for deploying, bakuping and migrating zones on hosts.}
  spec.homepage      = "https://github.com/simactom/master-thesis"
  spec.license       = "MIT"

  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_dependency "thor", "~> 0.20"
  spec.add_dependency "json-schema"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end